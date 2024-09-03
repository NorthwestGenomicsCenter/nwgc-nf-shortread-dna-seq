process GZIP {

    input:
        path fileToCompress

    output:
        path "${fileToCompress}.gz"

    script:
        """
        gzip \$(readlink ${fileToCompress})
        """
}