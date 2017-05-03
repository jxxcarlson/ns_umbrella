    [error] Task #PID<0.694.0> started from #PID<0.691.0> terminating
    ** (KeyError) key :src not found in: %{body: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<InitiateMultipartUploadResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\"><Bucket>noteimages</Bucket><Key>uploads/jupiter.jpg</Key><UploadId>jB6JHSwwSEDgv5fk0mMGUQVPmHnfxysaK3hdlT..i8bvTMKpd9EJciiHoGyAgYQ9DPvvNSGA8CMV.7mA5U2Bsr0GVobeJ3KC9.j9npXfz0uE2jPqFBfgelZsz0TJ6DJj</UploadId></InitiateMultipartUploadResult>", headers: [{"x-amz-id-2", "bIb7uA/L6SNJVhI5uc3BmANka5K7eQcP8pjUVy07F2i5KbNldXu9Hfy920QNId2yt88xEx9WI8s="}, {"x-amz-request-id", "19BCDB2CB6A22A08"}, {"Date", "Wed, 03 May 2017 21:00:26 GMT"}, {"Transfer-Encoding", "chunked"}, {"Server", "AmazonS3"}], status_code: 200}
        (ex_aws) lib/ex_aws/s3/upload.ex:83: ExAws.Operation.ExAws.S3.Upload.perform/2
        (arc) lib/arc/storage/s3.ex:57: Arc.Storage.S3.do_put/3
        (elixir) lib/task/supervised.ex:85: Task.Supervised.do_apply/2
        (elixir) lib/task/supervised.ex:36: Task.Supervised.reply/5
        (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
    Function: #Function<0.52315234/0 in Arc.Actions.Store.async_put_version/3>
        Args: []