The docker container has everything needed to run [Phasebook](https://github.com/phasebook/phasebook).

Phasebook is installed at `/build/phasebook`, so the main script is `/build/phasebook/scripts/phasebook.py`.

For example, to test on the small dataset provided by Phasebook:

```
python /build/phasebook/scripts/phasebook.py -i /build/phasebook/example/reads.fa -t 8 -p hifi -g small -x
```
