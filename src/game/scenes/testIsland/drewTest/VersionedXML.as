package game.scenes.testIsland.drewTest
{
	import com.poptropica.interfaces.INativeFileMethods;
	import com.poptropica.platformSpecific.Platform;
	import com.poptropica.platformSpecific.nativeClasses.NativeFileMethods;
	
	import engine.ShellApi;
	
	import org.osflash.signals.Signal;

	public class VersionedXML
	{
		private var _shellApi:ShellApi;
		
		private var _previousXML:XML;
		private var _nextXML:XML;
		private var _currentXML:XML;
		private var _previousLoaded:Boolean = false;
		private var _nextLoaded:Boolean = false;
		private var _url:String = "";
		
		public var loaded:Signal = new Signal(VersionedXML);
		
		public function VersionedXML(shellApi:ShellApi, url:String = "")
		{
			this._shellApi = shellApi;
			this.url = url;
		}
		
		public function get url():String { return this._url; }
		public function set url(url:String):void
		{
			if(url != null && this._url != url)
			{
				this._url = url;
				
				this._previousXML = null;
				this._nextXML = null;
				this._currentXML = null;
				
				this._previousLoaded = false;
				this._nextLoaded = false;
				
				this._shellApi.loadFile(this._shellApi.serverPrefix + this._shellApi.dataPrefix + url, nextXMLLoaded);
				this._shellApi.loadFile(this._shellApi.dataPrefix + url, previousXMLLoaded);
			}
		}
		
		public function get previousXML():XML { return this._previousXML; }
		public function get nextXML():XML { return this._nextXML; }
		public function get currentXML():XML { return this._currentXML; }
		
		private function previousXMLLoaded(xml:XML):void
		{
			this._previousXML = xml;
			this._previousLoaded = true;
			this.compare();
		}
		
		private function nextXMLLoaded(xml:XML):void
		{
			this._nextXML = xml;
			this._nextLoaded = true;
			this.compare();
		}
		
		private function compare():void
		{
			if(!this._previousLoaded) return;
			if(!this._nextLoaded) return;
			
			if(this._nextXML)
			{
				var fileMethods:INativeFileMethods = this._shellApi.fileManager.nativeMethods;
				NativeFileMethods;
				if(this._previousXML)
				{
					if(uint(this._nextXML.attribute("version")) > uint(this._previousXML.attribute("version")))
					{
						//Use the next one.
						this._currentXML = this._nextXML;
						
						//Need to copy/overwrite the file to local storage.
						//fileMethods.copyFileToStorage(
					}
					else
					{
						//Use the previous one.
						this._currentXML = this._previousXML;
					}
				}
				else
				{
					//Use the new one.
					this._currentXML = this._nextXML;
					
					//Need to copy/overwrite the file to local storage.
				}
			}
			else if(this._previousXML)
			{
				this._currentXML = this._previousXML;
			}
			else
			{
				//Nothing to use.
			}
			
			
			this.loaded.dispatch(this);
		}
	}
}