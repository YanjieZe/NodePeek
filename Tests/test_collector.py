import io
from pathlib import Path
import types
import unittest
from unittest.mock import patch

namespace = {}
source = (Path(__file__).resolve().parents[1] / 'Resources/collector.py').read_text()
exec(source.split('\nprevious = cpu_ticks()')[0], namespace)

class CollectorTests(unittest.TestCase):
    def test_cpu_excludes_guest_double_count(self):
        with patch('builtins.open', return_value=io.StringIO('cpu 10 20 30 40 5 6 7 8 100 200\n')):
            self.assertEqual(namespace['cpu_ticks'](), (126, 45))

    def run_sample(self, run):
        mem = 'MemTotal: 2097152 kB\nMemFree: 100 kB\nMemAvailable: 1048576 kB\n'
        with patch.dict(namespace, cpu_ticks=lambda: (200, 75)), patch('builtins.open', return_value=io.StringIO(mem)), patch('subprocess.run', **run):
            result, _ = namespace['sample']((100, 50))
        self.assertEqual(result['cpu'], 75)
        self.assertEqual(result['memoryUsed'], 1)
        self.assertEqual(result['memoryTotal'], 2)
        return result

    def test_gpu_unsupported_fields_are_null(self):
        result = types.SimpleNamespace(returncode=0, stdout='0, NVIDIA H100, 95, 1024, 81920, [N/A], [Not Supported]\n', stderr='')
        sample = self.run_sample({'return_value': result})
        self.assertEqual(sample['gpus'][0]['utilization'], 95)
        self.assertIsNone(sample['gpus'][0]['temperature'])
        self.assertIsNone(sample['gpus'][0]['power'])

    def test_cpu_memory_survive_missing_gpu_driver(self):
        sample = self.run_sample({'side_effect': FileNotFoundError()})
        self.assertEqual(sample['gpus'], [])
        self.assertIsNotNone(sample['gpuError'])

    def test_skip_gpu_never_calls_nvidia_smi(self):
        with patch.dict(namespace, SKIP_GPU=True):
            sample = self.run_sample({'side_effect': AssertionError('nvidia-smi must not run')})
        self.assertEqual(sample['gpus'], [])
        self.assertIsNone(sample['gpuError'])

    def test_processes_attach_to_their_gpu(self):
        gpu = types.SimpleNamespace(returncode=0, stdout='0, NVIDIA H100, 100, 50000, 143771, 60, 600, GPU-a\n1, NVIDIA H100, 0, 0, 143771, 30, 70, GPU-b\n', stderr='')
        apps = types.SimpleNamespace(returncode=0, stdout='GPU-a, 4242, 50000\n', stderr='')
        sample = self.run_sample({'side_effect': lambda args, **_: apps if '--query-compute-apps=gpu_uuid,pid,used_memory' in args else gpu})
        self.assertEqual([p['pid'] for p in sample['gpus'][0]['procs']], [4242])
        self.assertEqual(sample['gpus'][0]['procs'][0]['used'], 50000)
        self.assertEqual(sample['gpus'][1]['procs'], [])

    def test_short_command_prefers_run_name(self):
        short = namespace['short_command']
        self.assertEqual(short(['/venv/bin/python3.11', '-u', '/a/b/launch.py', '--lr', '1e-5', '--output_dir', '/data/runs/v5', '--experiment_name', 'v5']), 'v5 · launch.py')
        self.assertEqual(short(['python', '-m', 'trainer.main', '--config=/x/y/base.yaml']), 'base.yaml · main')
        self.assertEqual(short(['/usr/bin/vllm', 'serve', '/models/qwen']), 'vllm serve qwen')
        self.assertEqual(short([]), '')

if __name__ == '__main__': unittest.main()
