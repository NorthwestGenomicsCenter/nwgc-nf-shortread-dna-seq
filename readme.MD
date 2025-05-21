Basic Pipeline overview.
===
Multi‑Step Variant Calling Pipeline
A Nextflow pipeline to process raw Illumina BCL files through alignment, recalibration, variant calling, annotation, and validation using industry‑standard tools.

```mermaid
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
