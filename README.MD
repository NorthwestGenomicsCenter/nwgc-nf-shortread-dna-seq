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
    A[BCL files]
    A --> B["Demultiplex FastQs (BCL Convert 4.2.7)"]
    B --> C["Map to BAM (BWA‑MEM 0.7.15)"]
    C --> D["Mark Duplicates & Merge BAM (Picard 3.1.1)"]
    D --> E["Base Recalibration (GATK 3.7 BaseRecalibrator)"]
    E --> F["Quality Binning (GATK PrintReads 3.7)"]
    F --> G["Variant Calling (GATK HaplotypeCaller 4.2.0.0)"]
    G --> H["Variant Annotation (GATK VariantAnnotator 3.7)"]
    H --> I["Combine Variants (GATK CatVariants 3.7)"]
    I --> J["Validate Variants (GATK ValidateVariants 3.7)"]
```

```mermaid
---
title: Pipeline Overview
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
    E -. "Yes" .-> G
    G["bwa samse"]
    D -- "mapped.bam" --> H
    F -- "mapped.bam" --> H
    G -- "mapped.bam" --> H
    H@{ shape: fr-circ}
```
