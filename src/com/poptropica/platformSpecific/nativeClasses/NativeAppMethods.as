package com.poptropica.platformSpecific.nativeClasses
{
	import com.adobe.images.PNGEncoder;
	import com.poptropica.interfaces.INativeAppMethods;
	
	import flash.desktop.InvokeEventReason;
	import flash.desktop.NativeApplication;
	import flash.display.BitmapData;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.PermissionEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.CameraRoll;
	import flash.permissions.PermissionStatus;
	import flash.utils.ByteArray;
	
	import game.util.PlatformUtils;
	
	public class NativeAppMethods implements INativeAppMethods
	{
		public static const SAVE_COMOPLETE:String = "save successful";
		public static const SAVE_FAILED:String = "failed to save image to camera roll";
		public static const ACCESS_DENIED:String = "access denied";
		public static const PROCESSING_REQUEST:String = "processing request";
		public static const NOT_SUPPORTED:String = "device not supported";
		
		private var invoked:Boolean;
		private var _invokeURLArgs:Array = [];
		
		private var cameraRoll:CameraRoll;
		private var saveFile:File;
		private var picData:BitmapData;
		private var stream:FileStream;
		private var fileName:String;
		private var success:Function;
		private var failure:Function;
		
		//// CONSTRUCTOR ////
		
		public function NativeAppMethods()
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvocation);
			NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onActivated);
			NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, onDeactivated);
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, onExited);
		}
		
		//// ACCESSORS ////
		
		//// INTERNAL METHODS ////
		
		//// PROTECTED METHODS ////
		
		protected function onInvocation(e:InvokeEvent):void
		{
			invoked = true;
			
			switch (e.reason) {
				case InvokeEventReason.OPEN_URL:
					trace("This app has been invoked by a Custom URI Scheme", e.arguments[0]);
					_invokeURLArgs = e.arguments.concat();	// concat() makes a clone of the array
					break;
				default:
					trace("This app has been invoked. The reason?", e.reason);
					break;
			}
		}
		
		protected function onActivated(e:Event):void
		{
			trace("App activated");
		}
		
		protected function onDeactivated(e:Event):void
		{
			trace("App deactivated");
		}
		
		protected function onExited(e:Event):void
		{
			trace("App exiting");
		}
		
		public function get invokeURLArgs():Array {
			return invoked ? _invokeURLArgs : null;
		}
		
		public function get canExportToCameraRoll():Boolean {
			return CameraRoll.supportsAddBitmapData;
		}
		
		public function exportToCameraRoll(imageData:BitmapData, fileName:String = null, success:Function = null, failure:Function = null):Boolean
		{
			if(imageData == null || picData != null)
			{
				return false;
			}
			picData = imageData;
			this.fileName = fileName;
			this.success = success;
			this.failure = failure;
			
			if (cameraRoll == null)
			{
				cameraRoll = new CameraRoll();
			}
			
			if(canExportToCameraRoll)
			{
				if(CameraRoll.permissionStatus != PermissionStatus.GRANTED)
				{
					cameraRoll.addEventListener(PermissionEvent.PERMISSION_STATUS, onMobilePermissionComplete);
					cameraRoll.requestPermission();
				}
				else
				{
					saveToCameraRoll();
				}
			}
			else
			{
				signalComplete(NOT_SUPPORTED);
			}
			return true;
		}
		
		private function onMobilePermissionComplete(event:PermissionEvent):void
		{
			cameraRoll.removeEventListener(PermissionEvent.PERMISSION_STATUS, onMobilePermissionComplete);
			
			if(event.status == PermissionStatus.GRANTED)
			{
				saveToCameraRoll();
			}
			else
			{
				signalComplete(ACCESS_DENIED);
			}
		}
		
		private function saveToCameraRoll():void
		{
			cameraRoll.addEventListener(Event.COMPLETE, onAddComplete);
			cameraRoll.addEventListener(ErrorEvent.ERROR, onAddError);
			cameraRoll.addBitmapData(picData);
		}
		
		private function onAddError(event:ErrorEvent):void
		{
			cameraRoll.removeEventListener(Event.COMPLETE, onAddComplete);
			cameraRoll.removeEventListener(ErrorEvent.ERROR, onAddError);
			// older android devices diverged in methodology for saving
			// so adding additional support fot those devices
			if(PlatformUtils.isAndroid)
			{
				saveViaFileStream();
			}
			else
			{
				signalComplete(SAVE_FAILED);
			}
		}
		
		private function saveViaFileStream():void
		{
			var DCIMFolder:File = findAndroidFolder(File.getRootDirectories(), "DCIM");
			if (DCIMFolder)
			{
				trace("ExportToCameraRoll found DCIM folder");
				saveFile = DCIMFolder.resolvePath(fileName + ".png");
				saveFile.addEventListener(PermissionEvent.PERMISSION_STATUS, fileStreamPermissionDone);
				saveFile.requestPermission();
			}
			else
			{
				// if can't find DCIM folder, then failure
				signalComplete("Can't find DCIM folder");
			}
		}
		
		private function findAndroidFolder(fileArray:Array, match:String):File
		{
			var f:File;
			// iterate through directories
			for (var i:int = 0; i != fileArray.length; i++)
			{
				// if directory
				if (File(fileArray[i]).isDirectory)
				{
					// if match name then return file/directory
					if (File(fileArray[i]).name == match) return fileArray[i];
					// else scan nested directory
					f = findAndroidFolder(File(fileArray[i]).getDirectoryListing(), match);
					if (f != null) return f;
				}
			}
			return null;
		}
		
		private function fileStreamPermissionDone(event:PermissionEvent):void
		{
			saveFile.removeEventListener(PermissionEvent.PERMISSION_STATUS, fileStreamPermissionDone);
			
			if(event.status == PermissionStatus.GRANTED)
			{
				saveToFilStream();
			}
			else
			{
				signalComplete(ACCESS_DENIED);
			}
		}
		
		private function saveToFilStream():void
		{
			stream = new FileStream();
			var ba:ByteArray = PNGEncoder.encode(picData);
			
			// write byte array
			var hasErrors:Boolean = false;
			try
			{
				stream.open(saveFile, FileMode.WRITE);
				stream.writeBytes(ba);
				signalComplete(SAVE_COMOPLETE);
			}
			catch(e:Error)
			{
				signalComplete(e.message);
			}
			stream.close();
			stream = null;
		}
		
		private function onAddComplete(event:Event):void
		{
			cameraRoll.removeEventListener(Event.COMPLETE, onAddComplete);
			cameraRoll.removeEventListener(ErrorEvent.ERROR, onAddError);
			signalComplete(SAVE_COMOPLETE);
		}
		
		private function signalComplete(message:String):void
		{
			trace(message);
			if(message == SAVE_COMOPLETE)
			{
				if(success)
					success();
			}
			else
			{
				if(failure)
					failure();
			}
			//photoSaved.dispatch(message);
			picData = null;
			success = null;
			failure = null;
		}
	}
}