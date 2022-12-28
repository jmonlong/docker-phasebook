The docker container has everything needed to run [Phasebook](https://github.com/phasebook/phasebook).

Phasebook is installed at `/build/phasebook`, so the main script is `/build/phasebook/scripts/phasebook.py`.

For example, to test on the small dataset provided by Phasebook:

```
python /build/phasebook/scripts/phasebook.py -i /build/phasebook/example/reads.fa -t 8 -p hifi -g small -x
```

## Workflow in WDL

The WDL is defined in the `workflow.wdl` file. 
It can be tested locally, for example using the small read sets provided in the Phasebook repository (see `wdl-inputs-examples.json`):

```
## download reads from the Phasebook repo
wget https://raw.githubusercontent.com/phasebook/phasebook/master/example/reads.fa

## test workflow
java -jar $CROMWELL_JAR run workflow.wdl -i wdl-inputs-examples.json
```
