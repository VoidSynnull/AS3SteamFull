package org.assetloader.loaders
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import org.assetloader.base.AssetType;
	import org.assetloader.signals.LoaderSignal;
	
	/**
	 * @author Anthony Sawyer
	 */
	public class IosSWFLoader extends DisplayObjectLoader
	{
		/**
		 * @private
		 */
		protected var _swf : Sprite;
		private var _localBytes : ByteArray;
		
		/**
		 * @private
		 */
		protected var _onInit : LoaderSignal;
		
		public function IosSWFLoader(request : URLRequest, id : String = null)
		{
			if( request.url.search("app:/") != -1 
				&& request.url.search("app-storage:/") != -1 
				&& !File.applicationDirectory.resolvePath(request.url).exists 
				&& !File.applicationStorageDirectory.resolvePath(request.url).exists)
			{
				trace("IosSWFLoader :: " + request.url + " probably isn't on the device")
			}
			else
			{
				var filePath:File = new File(request.url);
				var inFileStream:FileStream = new FileStream();
				// TODO :: if file is not found we want to be able to handle failure gracefully - bard
				try
				{
					inFileStream.open(filePath, FileMode.READ);
					_localBytes = new ByteArray();
					inFileStream.readBytes(_localBytes);
				} 
				catch(error:Error) 
				{
					trace( "ERROR :: IosSWFLoader :: failed to open file: " + request.url + " ErrorID: " + error.errorID);
				}
				inFileStream.close();
				inFileStream = null;
			}
			super(request, id);
			_type = AssetType.SWF;
		}
		
		override protected function invokeLoading() : void
		{
			var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain)
			context.allowCodeImport = true;
			if(_localBytes == null)
			{
				this._onError.dispatch(this,"IO Error", "This file is not in the app or storage, try using SwfLoader");
				return;
			}
			_loader.loadBytes(_localBytes, context);// instead of context, it was: getParam(Param.LOADER_CONTEXT);
			context = null;
			_localBytes =null;
		}
		
		/**
		 * @private
		 */
		override protected function initSignals() : void
		{
			super.initSignals();
			_onInit = new LoaderSignal();
			_onComplete = new LoaderSignal(Sprite);
		}
		
		protected function init_handler(event : Event) : void
		{
			_data = _displayObject = _loader.content;
			
			_onInit.dispatch(this, _data);
		}
		
		/**
		 * @private
		 */
		override protected function addListeners(dispatcher : IEventDispatcher) : void
		{
			super.addListeners(dispatcher);
			if(dispatcher)
				dispatcher.addEventListener(Event.INIT, init_handler);
		}
		
		/**
		 * @private
		 */
		override protected function removeListeners(dispatcher : IEventDispatcher) : void
		{
			super.removeListeners(dispatcher);
			if(dispatcher)
				dispatcher.removeEventListener(Event.INIT, init_handler);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function destroy() : void
		{
			super.destroy();
			_swf = null;
			_localBytes = null;
		}
		
		/**
		 * @private
		 * 
		 * @inheritDoc
		 */
		override protected function testData(data : DisplayObject) : String
		{
			var errMsg : String = "";
			try
			{
				_data = _swf = Sprite(data);
			}
			catch(error : Error)
			{
				errMsg = error.message;
			}
			return errMsg;
		}
		
		/**
		 * Gets the resulting Sprite after loading is complete.
		 * 
		 * @return Sprite
		 */
		public function get swf() : Sprite
		{
			return _swf;
		}
		
		/**
		 * Dispatched when the properties and methods of a loaded SWF file are accessible and ready for use.
		 * 
		 * <p>HANDLER ARGUMENTS: (signal:<strong>LoaderSignal</strong>)</p>
		 * <ul>
		 *	 <li><strong>signal</strong> - The signal that dispatched.</li>
		 * </ul>
		 * 
		 * @see org.assetloader.signals.LoaderSignal
		 */
		public function get onInit() : LoaderSignal
		{
			return _onInit;
		}
	}
}