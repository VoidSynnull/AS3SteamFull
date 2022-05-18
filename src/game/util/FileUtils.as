package game.util
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class FileUtils
	{
		/**
		 * Writes an XML to app-storage at the given file path. This overwrites any existing XML.
		 * <p>For Poptropica, the path should only be:
		 * <li>poptropica.com/game/[path]</li>
		 * <li>bin/[path]</li>
		 * </p>
		 * @param XML The XML to write to app-storage.
		 * @param path The file path to the XML.
		 */
		public static function writeXMLToAppStorage(xml:XML, path:String):Boolean
		{
			if(xml && path)
			{
				var byteArray:ByteArray = new ByteArray();
				byteArray.writeUTFBytes(xml.toXMLString());
				
				var file:File = File.applicationStorageDirectory.resolvePath(path);
				file.preventBackup = true;
				
				var fileStream:FileStream = new FileStream(); 
				fileStream.open(file, FileMode.WRITE); 
				fileStream.writeBytes(byteArray); 
				fileStream.close();
				return true;
			}
			return false;
		}

		public static function readStringFromAppStorage(filePath:String):String
		{
			var fileContents:String;
			try {
				var stream:FileStream = new FileStream();
				stream.open(File.applicationStorageDirectory.resolvePath(filePath), FileMode.READ);
				fileContents = stream.readUTFBytes(stream.bytesAvailable);
				stream.close();
			} catch(e:Error) {
				trace("WARNING FileUtils::readStringFromAppStorage() encountered an error trying to read ID file", e.message);
			}
			return fileContents;
		}

		public static function writeStringToAppStorage(filePath:String, s:String):Boolean
		{
			var success:Boolean = false;
			try {
				var file:File = File.applicationStorageDirectory.resolvePath(filePath);
				file.preventBackup = true;
				var stream:FileStream = new FileStream();
				stream.open(file, FileMode.WRITE);
				stream.writeUTFBytes(s);
				stream.close();
				success = true;
			} catch(e:Error) {
				trace("WARNING FileUtils::writeStringToAppStorage() encountered an error trying to write", s, "to file", filePath);
			}
			return success;
		}

	}

}
