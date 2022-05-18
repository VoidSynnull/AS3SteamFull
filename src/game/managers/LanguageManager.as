package game.managers
{
	import flash.utils.Dictionary;
	
	import engine.Manager;
	import engine.managers.FileManager;
	import engine.util.Command;
	
	import game.util.DataUtils;
	
	/**
	 * Author: Drew Martin
	 */
	public class LanguageManager extends Manager
	{
		private var _fileManager:FileManager;
		
		public const LANGUAGES_FOLDER:String = "languages/";
		
		public const DELIMITER:String = ".";
		
		/**
		 * A Dictionary of localized text Strings that can be accessed by their <code>id</code>.
		 */
		private var _dictionary:Dictionary = new Dictionary();
		
		/**
		 * Used for debugTrace() String counting.
		 */
		private var _numStrings:int = 0;
		
		/**
		 * Author: Drew Martin
		 * 
		 * <p>At its core, Language Manager is a Dictionary of key/value pairs.
		 * <ol>
		 * 		<li><b>Keys</b></li>
		 * 		<ol>
		 * 			<li>Keys are dot(.)-delimited Strings to allow for nested searching.</li>
		 * 			<li>A key of <code>island.scene.id</code> would get accessed as <code>dictionary["island"]["scene"]["id"]</code>.</li>
		 * 		</ol>
		 * 		<li><b>Values</b></li>
		 * 		<ol>
		 * 			<li>Values are either Strings or Dictionaries, depending on the key.</li>
		 * 			<li>When attempting to get a value, a default value can be supplied should the look up fail.</li>
		 * 		</ol>
		 * 		<li><b>XMLs</b></li>
		 * 		<ol>
		 * 			<li>XMLs may be added directly to the Dictionary.</li>
		 * 			<li>The children/parentage of the XML elements determines the nesting of key values.</li>
		 * 			<li>
		 * 				<language>
		 * 					<island>
		 * 						<scene>
		 * 							<id>A String in dictionary["island"]["scene"]["id"].</id>
		 * 						</scene>
		 * 						<id>A String in dictionary["island"]["id"].</id>
		 * 					</island>
		 * 					<id>A String in dictionary["id"].</id>
		 * 				</language> 
		 * 			</li>
		 * 		</ol>
		 * </ol>
		 */
		public function LanguageManager()
		{
			
		}
		
		override protected function construct():void
		{
			if(this.shellApi.getManager(FileManager))
			{
				this.getFileManager(this.shellApi.getManager(FileManager));
			}
			else
			{
				this.shellApi.managerAdded.add(this.getFileManager);
			}
		}
		
		private function getFileManager(manager:Manager):void
		{
			if(manager is FileManager)
			{
				this.shellApi.managerAdded.remove(this.getFileManager);
				this._fileManager = FileManager(manager);
				this.loadAndAddXML("shared");
			}
		}
		
		/**
		 * Returns the total number of Strings in the entire Dictionary tree.
		 */
		public final function get numStrings():int { return this._numStrings; }
		
		/**
		 * Returns the entire Dictionary.
		 */
		public final function get dictionary():Dictionary { return this._dictionary; }
		
		/**
		 * Clears the Dictionary's contents.
		 */
		public final function clear():void
		{
			this._dictionary = new Dictionary();
			this._numStrings = 0;
		}
		
		/**
		 * Gets a String or Dictionary with the given <code>key</code> from the Dictionary. If a String or
		 * Dictionary with the given <code>key</code> isn't found, the <code>defaultText</code> is returned.
		 */
		public final function get(key:String, defaultText:String = ""):*
		{
			var value:* 	= this._dictionary;
			var keys:Array 	= key.split(DELIMITER);
			var length:int	= keys.length - 1;
			
			//Dictionary traversal.
			for(var index:int = 0; index < length; ++index)
			{
				value = value[keys[index]];
				if(!value) return defaultText;
			}
			
			//Get final String or Dictionary.
			value = value[keys[length]];
			
			return value ? value : defaultText;
		}
		
		/**
		 * Adds a String with the given <code>key</code> to the Dictionary.
		 */
		public final function add(key:String, text:String):void
		{
			var value:* 	= this._dictionary;
			var keys:Array 	= key.split(DELIMITER);
			var length:int	= keys.length - 1;
			
			//Dictionary traversal.
			for(var index:int = 0; index < length; ++index)
			{
				var nextValue:* = value[keys[index]];
				/*
				TO-DO :: If nextValue is a String already, and it's supposed to be a Dictionary for a newly added
				String, then we may want to do some extra checking.
				*/
				if(!nextValue)
				{
					nextValue = value[keys[index]] = new Dictionary();
				}
				value = nextValue;
			}
			
			//Add final String.
			value[keys[length]] = text;
			++this._numStrings;
		}
		
		/**
		 * Adds an XML to the Dictionary. If an optional <code>key</code> String is specified, then the
		 * XML will get added at that starting key.
		 */
		public final function addXML(xml:XML, key:String = ""):void
		{
			if(key) key += DELIMITER;
			
			var childrenXML:XMLList = xml.children();
			for each(var childXML:XML in childrenXML)
			{
				if(childXML.hasComplexContent())
				{
					this.addXML(childXML, key + childXML.name());
				}
				else
				{
					this.add(key + childXML.name(), childXML);
				}
			}
		}
		
		/**
		 * Loads and adds an XML to the Dictionary.
		 */
		public final function loadAndAddXML(filePath:String, language:String = "", handler:Function = null):void
		{
			language = DataUtils.validString(language) ? language : this.shellApi.preferredLanguage;	
			filePath 	= _fileManager.dataPrefix + LANGUAGES_FOLDER + language + "/" + filePath + "/language.xml";
			_fileManager.loadFile(filePath, Command.create(this.addLoadedXML, handler));
		}
		
		private final function addLoadedXML(xml:XML, handler:Function = null):void
		{
			this.addXML(xml);
			if(handler != null) handler();
		}
		
		/**
		 * Removes a String or Dictionary with the given <code>key</code> from the Dictionary.
		 */
		public final function remove(key:String):Boolean
		{
			var value:* 	= this._dictionary;
			var keys:Array 	= key.split(DELIMITER);
			var length:int	= keys.length - 1;
			
			//Dictionary traversal.
			for(var index:int = 0; index < length; ++index)
			{
				value = value[keys[index]];
				if(!value) return false;
			}
			
			//Remove final String or Dictionary.
			if(value[keys[length]])
			{
				delete value[keys[length]];
				--this._numStrings;
				
				return true;
			}
			
			return false;
		}
		
		/**
		 * Removes an XML from the Dictionary. If an optional <code>key</code> String is specified, then the
		 * XML will get removed at that starting key.
		 */
		public final function removeXML(xml:XML, key:String = ""):void
		{
			if(key) key += DELIMITER;
			
			var childrenXML:XMLList = xml.children();
			for each(var childXML:XML in childrenXML)
			{
				if(childXML.hasComplexContent())
				{
					this.removeXML(childXML, key + childXML.name());
				}
				else
				{
					this.remove(key + childXML.name());
				}
			}
		}
		
		/**
		 * Loads and removes an XML from the Dictionary.
		 */
		public final function loadAndRemoveXML(filePath:String, language:String = "", handler:Function = null):void
		{
			language 	= language ? language : this.shellApi.preferredLanguage;
			filePath 	= _fileManager.dataPrefix + LANGUAGES_FOLDER + language + "/" + filePath + "/language.xml";
			_fileManager.loadFile(filePath, Command.create(this.removeLoadedXML, handler));
		}
		
		private final function removeLoadedXML(xml:XML, handler:Function = null):void
		{
			this.removeXML(xml);
			if(handler != null) handler();
		}
		
		/**
		 * Does a debug trace() of the Dictionary's contents. Keys are reformatted back into a
		 * <code>island.scene.id = text</code> String to better visualize what Dictionaries the Strings reside.
		 */
		public final function debugTrace():void
		{
			trace("===Language Manager Debug Trace===");
			
			this.traceDictionary(this._dictionary);
			
			trace("Num Strings:", this._numStrings);
		}
		
		public final function traceDictionary(dictionary:Dictionary, previousKey:String = ""):void
		{
			if(previousKey) previousKey += DELIMITER;
			
			for(var key:String in dictionary)
			{
				var value:* = dictionary[key];
				
				if(value is Dictionary)
				{
					this.traceDictionary(value, previousKey + key);
				}
				else
				{
					trace(previousKey + key + " = " + value);
				}
			}
		}
	}
}