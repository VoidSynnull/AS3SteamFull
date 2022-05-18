package engine.managers
{
	import flash.net.URLLoader;

	public class ZipFileRequest
	{
		public function ZipFileRequest(url:String, remote:Boolean = false, deleteOnComplete:Boolean = true)
		{
			this.url = url;
			this.remote = remote;
			this.deleteOnComplete = deleteOnComplete;
		}
		
		public var url:String;
		public var remote:Boolean;
		public var deleteOnComplete:Boolean;
		public var urlLoader:URLLoader;
	}
}