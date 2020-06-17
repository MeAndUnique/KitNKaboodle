Remove-Item -Path ConstitutionalAmendments.zip -ErrorAction Ignore
Compress-Archive -Path source\* -DestinationPath ConstitutionalAmendments.zip
Remove-Item -Path ConstitutionalAmendments.ext
Rename-Item -Path ConstitutionalAmendments.zip -NewName ConstitutionalAmendments.ext -Force