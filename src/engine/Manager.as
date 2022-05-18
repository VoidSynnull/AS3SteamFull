package engine
{
	public class Manager
	{
		internal var _shellApi:ShellApi;
		
		public function Manager()
		{
			
		}
		
		internal function addedToEngine(shellApi:ShellApi):void
		{
			this._shellApi = shellApi;
			this.construct();
		}
		
		internal function removedFromEngine():void
		{
			this.destroy();
		}
		
		protected function construct():void
		{
			
		}
		
		protected function destroy():void
		{
			this._shellApi = null;
		}
		
		public function get shellApi():ShellApi { return this._shellApi; }
	}
}