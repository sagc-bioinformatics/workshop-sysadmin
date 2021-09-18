WGBS-specific information on data set generation, packaging and upload.

# Generate Data Set

```bash
conda activate wgbs
mkdir -p /data/wgbs/

# Do stuff and put the data in /data/wgbs/
```

# Package Data Set

Package the data set and upload to CloudStor

```bash
tar -c -f wgbs.tar /data/wgbs

# cleanup
#rm -f *.fastq.gz *.tsv
```
