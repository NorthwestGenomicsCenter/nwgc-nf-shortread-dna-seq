Basic Pipeline overview.
===
Multi‑Step Variant Calling Pipeline
A Nextflow pipeline to process raw Illumina BCL files through alignment, recalibration, variant calling, annotation, and validation using industry‑standard tools.

```mermaid
graph LR
    A[BCL files]
    A --> B[Demultiplex FastQs<br/>(BCL Convert 4.2.7)]
    B --> C[Map to BAM<br/>(BWA‑MEM 0.7.15)]
    C --> D[Mark Duplicates & Merge BAM<br/>(Picard 3.1.1)]
    D --> E[Base Recalibration<br/>(GATK 3.7 BaseRecalibrator)]
    E --> F[Quality Binning<br/>(GATK PrintReads 3.7)]
    F --> G[Variant Calling<br/>(GATK HaplotypeCaller 4.2.0.0)]
    G --> H[Variant Annotation<br/>(GATK VariantAnnotator 3.7)]
    H --> I[Combine Variants<br/>(GATK CatVariants 3.7)]
    I --> J[Validate Variants<br/>(GATK ValidateVariants 3.7)]
```
