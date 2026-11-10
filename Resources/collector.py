import csv, io, json, os, pwd, subprocess, sys, time

# 'nogpu' keeps nvidia-smi from opening the driver, so the host can reset GPUs or unload the module.
SKIP_GPU = 'nogpu' in sys.argv[1:]

def cpu_ticks():
    with open('/proc/stat') as f:
        values = list(map(int, f.readline().split()[1:9]))
    return sum(values), values[3] + values[4]

# Flags that usually name the run; shown instead of the full argument list.
RUN_FLAGS = ('experiment_name', 'exp_name', 'run_name', 'name', 'output_dir', 'config_name', 'config', 'task')

def short_command(argv):
    # Run name first so it survives truncation: '... /a/launch.py --lr 1e-5 --output_dir /data/runs/v5' -> 'v5 · launch.py'
    if not argv:
        return ''
    def base(arg):
        return arg.rstrip('/').rsplit('/', 1)[-1] if '/' in arg.rstrip('/') else arg
    exe = base(argv[0])
    head = ['python' if exe.startswith('python') else exe]
    args = [a for a in argv[1:] if a != '-u']
    if len(args) > 1 and args[0] == '-m':
        head += ['-m', args[1]]; rest = args[2:]
    elif args and not args[0].startswith('-'):
        head.append(base(args[0])); rest = args[1:]
    else:
        rest = args
    picks, seen = [], set()
    for i, arg in enumerate(rest):
        if not arg.startswith('--'):
            continue
        key, _, value = arg[2:].partition('=')
        if not value and i + 1 < len(rest) and not rest[i + 1].startswith('--'):
            value = rest[i + 1]
        value = base(value)
        if key.replace('-', '_') in RUN_FLAGS and value and value not in seen:
            seen.add(value); picks.append(value)
    if picks:
        program = head[-1].rsplit('.', 1)[-1] if len(head) > 2 and head[1] == '-m' else head[-1]
        return ' · '.join(picks[:2] + [program])[:160]
    return ' '.join(head + [base(a) for a in rest])[:160]

def gpu_processes():
    # {gpu_uuid: [{pid, user, used, command, full}]}; processes in another PID namespace show as user '?'.
    try:
        result = subprocess.run(['nvidia-smi', '--query-compute-apps=gpu_uuid,pid,used_memory', '--format=csv,noheader,nounits'], capture_output=True, text=True, timeout=3)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return {}
    if result.returncode:
        return {}
    procs = {}
    for row in csv.reader(io.StringIO(result.stdout)):
        if len(row) != 3:
            continue
        uuid, pid = row[0].strip(), row[1].strip()
        try: used = float(row[2].strip())
        except ValueError: used = None
        user, argv = '?', []
        try:
            with open('/proc/%s/status' % pid) as f:
                uid = next(int(line.split()[1]) for line in f if line.startswith('Uid:'))
            try: user = pwd.getpwuid(uid).pw_name
            except KeyError: user = str(uid)
            with open('/proc/%s/cmdline' % pid, 'rb') as f:
                argv = [a.decode('utf-8', 'replace') for a in f.read().split(b'\0') if a]
        except (OSError, StopIteration, ValueError):
            pass
        procs.setdefault(uuid, []).append(dict(pid=int(pid) if pid.isdigit() else 0, user=user, used=used, command=short_command(argv), full=' '.join(argv)[:600]))
    return procs

def sample(previous):
    current = cpu_ticks()
    delta = current[0] - previous[0]
    cpu = max(0, min(100, 100 * (1 - (current[1] - previous[1]) / delta))) if delta else 0
    with open('/proc/meminfo') as f:
        memory = {line.split(':')[0]: int(line.split()[1]) for line in f}
    total = memory['MemTotal']
    available = memory.get('MemAvailable', memory.get('MemFree', 0))
    gpus, error = [], None
    if not SKIP_GPU:
        try:
            result = subprocess.run(['nvidia-smi', '--query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,uuid', '--format=csv,noheader,nounits'], capture_output=True, text=True, timeout=3)
            if result.returncode:
                error = result.stderr.strip()[:250] or 'nvidia-smi failed'
            else:
                procs = gpu_processes()
                for row in csv.reader(io.StringIO(result.stdout)):
                    if len(row) not in (7, 8):
                        continue
                    def number(value):
                        try: return float(value.strip())
                        except ValueError: return None
                    gpus.append(dict(index=row[0].strip(), name=row[1].strip(), utilization=number(row[2]), used=number(row[3]), total=number(row[4]), temperature=number(row[5]), power=number(row[6]), procs=procs.get(row[7].strip(), []) if len(row) == 8 else []))
        except FileNotFoundError:
            error = 'nvidia-smi not found (no NVIDIA GPU or driver installed)'
        except subprocess.TimeoutExpired:
            error = 'nvidia-smi timed out'
    return dict(cpu=cpu, cores=os.cpu_count() or 0, memoryUsed=(total-available)/1048576, memoryTotal=total/1048576, gpus=gpus, gpuError=error), current

previous = cpu_ticks()
time.sleep(1)
while True:
    data, previous = sample(previous)
    print(json.dumps(data), flush=True)
    time.sleep(5)
