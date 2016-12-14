The application is run through 'app.rb'

There is a provided userList.csv that is used by default for testing purposes,
containing usernames, passwords, and roles.

The initial admin account for uploading CSV files and website zips
username: admin
password: admin

CSV file format for users:
name,password,role

Roles: Student, Admin

Zip file format:
bootstrapWebsite.zip
 - Entry 1 (folder)
   = bootstrap.html
 - Entry 2 (folder)
   = boostrap.html
 etc.

Zip file is extracted to /public/files/

Ruby code will display bootstrap.html

Examples of files to upload are included:
userList.csv
bootstrapWebsites.zip