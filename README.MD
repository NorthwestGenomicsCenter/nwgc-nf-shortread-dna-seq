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

```mermaid
---
title: Merge
---
flowchart TD
    A["Mapping"] -- "mapped.bam" --> B
    style A fill:#E0E0E0
    A -- "mapped.bam" --> B
    A -- "mapped.bam" --> B
    B["Picard MarkDuplicates"] -- "merged.bam" --> C
    C["GATK BaseRecalibrator"] -- "recalibration.matrix" --> D
    D["GATK PrintReads"] -- "merged.recalibrated.bam" --> E
    E@{ shape: fr-circ}
```

```mermaid
---
title: Merge QC
---
flowchart TD
    A["Merge"] -- "merged.recalibrated.bam" --> B
    style A fill:#E0E0E0
    B["Merge QC"] -- "merged.recalibrated.bam" --> C
    C["Picard Coverage Metrics"]
    B -- "merged.recalibrated.bam" --> D
    D["Picard Coverage<BR> Metrics By Chrom"]
    B -- "merged.recalibrated.bam" --> E
    E["Contamination"]
    B -- "merged.recalibrated.bam" --> F
    F["Picard Multiple Metrics"]
    B -- "merged.recalibrated.bam" --> G
    G["Samtools Flagstat"]
    B -- "merged.recalibrated.bam" --> H
    H["Samtools Stats"]
    B -- "merged.recalibrated.bam" --> I
    I["Fingerprint"]
    B -- "merged.recalibrated.bam" --> J
    J["Collect and Plot"]
    C -- "BASEQ0.MAPQ20.cov<BR>BASEQ10.MAPQ20.cov<BR>BASEQ20.MAPQ20.cov<BR>BASEQ30.MAPQ20.cov<BR>BASEQ20.MAPQ0.cov" --> K
    K@{shape: fr-circ}
    D -- "One cov file per chrom" --> L
    L@{shape: fr-circ}
    E -- "VerifyBamId.selfSM" --> M
    M@{shape: fr-circ}
    F -- "alignment_summary_metrics.txt<BR>base_distribution_by_cycle.txt<BR>gc_bias_metrics.txt<BR>gc_bias_summary_metrics.txt<BR>insert_size_metrics.txt<BR>quality_yield_metrics.txt<BR>base_distribution_by_cycle.pdf<BR>insert_size_histogram.pdf<BR>gc_bias.pdf" --> N
    N@{shape: fr-circ}
    G -- "flagstat.output.txt" --> O
    O@{shape: fr-circ}
    H -- "onTarget.stats.txt" --> P
    P@{shape: fr-circ}
    I -- "fingerprint.vcf.gz" --> Q
    Q@{shape: fr-circ}
    J -- "readSummary.txt<BR>q20sByChrom.txt<BR>MIN20.corrected.wgs.metrics.txt" --> R
    R@{shape: fr-circ}
```
```mermaid
---
title: Variant Calling (Main)
---
flowchart TD
    A["Merge"] -- "merged.recalibrated.bam" --> B
    style A fill:#E0E0E0
    B["GATK HaplotypeCaller"] -- "chrom1.gvcf" --> C
    C["GATK VariantAnnnotator"] -- "chrom1.annotated.gvcf" --> H
    A -- "merged.recalibrated.bam" --> D
    D["GATK HaplotypeCaller"] -- "chrom2.gvcf" --> E
    E["GATK VariantAnnnotator"] -- "chrom2.annotated.gvcf" --> H
    A -- "merged.recalibrated.bam" --> F
    F["GATK HaplotypeCaller"] -- "chromN.gvcf" --> G
    G["GATK VariantAnnnotator"] -- "chromN.annotated.gvcf" --> H
    H["GATK CatVariants"] -- "main.combined.gvcf" --> I
    I@{shape: fr-circ}```

```mermaid
---
title: Variant Calling (Filtered)
---
flowchart TD
    A["Merge"] -- "merged.recalibrated.bam" --> B
    style A fill:#E0E0E0
    B["GATK HaplotypeCaller"] -- "chrom1.gvcf" --> C
    C["GATK VariantAnnnotator"] -- "chrom1.annotated.gvcf" --> D
    D["GATK VariantFiltration"] -- "chrom1.annotated.filtered.gvcf" --> K
    A -- "merged.recalibrated.bam" --> E
    E["GATK HaplotypeCaller"] -- "chrom2.gvcf" --> F
    F["GATK VariantAnnnotator"] -- "chrom2.annotated.gvcf" --> G
    G["GATK VariantFiltration"] -- "chrom2.annotated.filtered.gvcf" --> K
    A -- "merged.recalibrated.bam" --> H
    H["GATK HaplotypeCaller"] -- "chromN.gvcf" --> I
    I["GATK VariantAnnnotator"] -- "chromN.annotated.gvcf" --> J
    J["GATK VariantFiltration"] -- "chromN.annotated.filtered.gvcf" --> K
    K["GATK CatVariants (Filtered)"] -- "filtered.combined.gvcf" --> L
    L@{shape: fr-circ}
 ```
