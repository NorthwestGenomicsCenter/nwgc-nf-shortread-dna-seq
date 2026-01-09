# nwgc-nf-shortread-rna-seq
[![License](https://img.shields.io/badge/license-GPLv3-blue)](https://www.gnu.org/licenses/gpl-3.0.txt)

Contact: nwgc-software@uw.edu

----

## Introduction

Short Read DNA Multi‑Step Variant Calling Pipeline
A Nextflow pipeline to process raw Illumina BCL files through alignment, recalibration, variant calling, annotation, and validation using industry‑standard tools.

```mermaid
---
title: Pipeline Overview
---
graph TB
    A["Demulitplex Pipeline"] -- "flowCellLane1.fastq" --> B
    style A fill:#E0E0E0
    A -- "flowCellLane2.fastq" --> C
    A -- "flowCellLaneN.fastq" --> D
    B["Mapping"] -- "mapped.bam" --> E
    C["Mapping"] -- "mapped.bam" --> E
    D["Mapping"] -- "mapped.bam" --> E
    E["Merge"] -- "merged.bam" --> F
    F@{shape: fr-circ}
    F --> G
    G["QC"]
    F --> H
    H["Variant Calling"]
    F --> I
    I["Polymorphic QC"]
```

```mermaid
---
title: Mapping
---
flowchart TD
    A["Demultiplex Pipeline"] -- "flowCellLane.fastq" --> B
    style A fill:#E0E0E0
    B["Lane Map"] .-> C
    C@{shape: diamond, label: "Read<BR> Length<BR> >= 75bp"}
    style C fill:#ffffcc
    style C font-size:0.9em
    C -. "Yes" .-> D
    D["bwa mem"]
    C -. "No" .-> E
    E@{ shape: diamond, label: "Paired<BR> End?" }
    style E fill:#ffffcc
    style E font-size:0.9em
    E -. "Yes" .-> F
    F["bwa sampe"]
    E -. "No" .-> G
    G["bwa samse"]
    D -- "mapped.bam" --> H
    F -- "mapped.bam" --> H
    G -- "mapped.bam" --> H
    H["Mapping QC"]
```

```mermaid
---
title: Mapping QC
---
flowchart TD
    A["Mapping"] -- "mapped.bam" --> B
    style A fill:#E0E0E0
    B["Mapping QC"] -- "mapped.bam" --> C
    C["Picard Coverage Metrics"]
    B["Mapping QC"] -- "mapped.bam" --> D
    D["Picard Coverage<BR> Metrics By Chrom"]
    B["Mapping QC"] -- "mapped.bam" --> E
    E["Contamination"]
    B["Mapping QC"] -- "mapped.bam" --> F
    F["Picard Multiple Metrics"]
    B["Mapping QC"] -- "mapped.bam" --> G
    G["Samtools Flagstat"]
    B["Mapping QC"] -- "mapped.bam" --> H
    H["Samtools Stats"]
    C -- "BASEQ0.MAPQ20.cov<BR>BASEQ10.MAPQ20.cov<BR>BASEQ20.MAPQ20.cov<BR>BASEQ30.MAPQ20.cov<BR>BASEQ20.MAPQ0.cov" --> I
    I@{shape: fr-circ}
    D -- "One cov file per chrom" --> J
    J@{shape: fr-circ}
    E -- "VerifyBamId.selfSM" --> K
    K@{shape: fr-circ}
    F -- "alignment_summary_metrics.txt<BR>base_distribution_by_cycle.txt<BR>gc_bias_metrics.txt<BR>gc_bias_summary_metrics.txt<BR>insert_size_metrics.txt<BR>quality_yield_metrics.txt<BR>base_distribution_by_cycle.pdf<BR>insert_size_histogram.pdf<BR>gc_bias.pdf" --> L
    L@{shape: fr-circ}
    G -- "flagstat.output.txt" --> M
    M@{shape: fr-circ}
    H -- "onTarget.stats.txt" --> N
    N@{shape: fr-circ}
```
