{
 "Version": "2012–10–17",
 "Id": "NoteShareImagePolicy",
 "Statement": [
 {
 "Sid": "Stmt1380877761162",
 "Effect": "Allow",
 "Principal": {
 "AWS": "*"
 },
 "Action": "s3:GetObject",
 "Resource": "arn:aws:s3:::noteimages/*"
 }
 ]
}