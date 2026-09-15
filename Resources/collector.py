import csv, io, json, os, subprocess, time

def cpu_ticks():
    with open('/proc/stat') as f:
        values = list(map(int, f.readline().split()[1:9]))
    return sum(values), values[3] + values[4]

def sample(previous):
    current = cpu_ticks()
    delta = current[0] - previous[0]
    cpu = max(0, min(100, 100 * (1 - (current[1] - previous[1]) / delta))) if delta else 0
    with open('/proc/meminfo') as f:
        memory = {line.split(':')[0]: int(line.split()[1]) for line in f}
    total = memory['MemTotal']
    available = memory.get('MemAvailable', memory.get('MemFree', 0))
    gpus, error = [], None
    try:
        result = subprocess.run(['nvidia-smi', '--query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw', '--format=csv,noheader,nounits'], capture_output=True, text=True, timeout=3)
        if result.returncode:
            error = result.stderr.strip()[:250] or 'nvidia-smi failed'
        else:
            for row in csv.reader(io.StringIO(result.stdout)):
                if len(row) != 7:
                    continue
                def number(value):
                    try: return float(value.strip())
                    except ValueError: return None
                gpus.append(dict(index=row[0].strip(), name=row[1].strip(), utilization=number(row[2]), used=number(row[3]), total=number(row[4]), temperature=number(row[5]), power=number(row[6])))
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
