package game.scenes.examples.itemExample
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	
	import fl.controls.ComboBox;
	
	import game.components.entity.character.part.SkinPart;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scene.template.PlatformerGameScene;
	import game.systems.entity.SkinSystem;
	import game.util.SceneUtil;
	import game.util.SkinUtils;

	//import game.util.TribeUtils;
	
	public class ItemExample extends PlatformerGameScene
	{
		private var _files : Array = new Array();
		private var _currentPartIndex : uint = 0;
		private var _currentType:String = "hair"
		private var _currentTypeIndex : uint = 0;
		private var _halt:Boolean = true;
		
		private var _tfType:TextField;
		private var _tfPart:TextField;
		private var _tfError:TextField;
		
		private var _npc:Entity;

		private var _partFiles : Array = new Array();
		private var _partTypes : Vector.<String> = new<String>["hair", "pack", "item", "facial", "marks", "pants", "overpants", "shirt", "overshirt", "mouth"];
		private var _partErrorTimer : uint;
		private var _partCycleTimer : uint;
		
		private var _errorLogs:Vector.<String> = new Vector.<String>();
		private var _waitTime:Number = 100;
		
		private var _partDicts:Dictionary; // Dictionary of Vector.<String>, Dict key = part type, vector contains names of parts of key's type
		
		public function ItemExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/itemExample/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			_npc = super.getEntityById( "dummyNpc" );
			
			setupPartChecker();
			
			giveCards();
			super.loaded();
		}
		
		private function receiveItems():void
		{
			super.shellApi.getItem( "tribe_specific_card", null, true );
			super.shellApi.getItem( "standard_card", null, true );
		}
		
		/**
		 * Automatically give the player example cards
		 */
		private function giveCards():void
		{
			//get store cards
			var startIndex:int = 3000;
			var maxStore:int = 100;
			for (var i:int = startIndex + maxStore; i >= startIndex; i--) 
			{
				shellApi.getItem( String(i), "store" );
			}
		}
		
		private function setupPartChecker():void
		{
			SkinSystem( super.getSystem( SkinSystem )).errorSignal.add( logError );
			
			var partFolders : Array = File.applicationDirectory.resolvePath("data/entity/character/parts").getDirectoryListing();
			var partFolder:File;
			var partFiles:Array;
			var partNames:Vector.<String>;
			var partFileURL : String
			var partName : String
			
			_partDicts = new Dictionary();
			
			for (var i:int = 0; i < partFolders.length; i++) 
			{
				partFolder = partFolders[i];
				if( _partTypes.indexOf( partFolder.name ) != -1 )	// proces only specified parts as determined by _partTypes 
				{
					partNames = new Vector.<String>();
					_partDicts[partFolder.name] = partNames;
					partFiles = partFolder.getDirectoryListing();
					for (var k:int = 0; k < partFiles.length; k++) 
					{	
						partFileURL = File(partFiles[k]).url
						partName  = partFileURL.substring(partFileURL.lastIndexOf("/")+1, partFileURL.lastIndexOf("."));
						if( partName != "" )
						{
							partNames.push(partName);
						}
					}
				}
			}
			
			setupTextDisplay();
			setupButtons();
			setupComboBoxes();    // add part type combo boxes for manual testing
			toggleLookTarget();
		}
		
		private function setupTextDisplay():void
		{
			_tfType = MovieClip(super._hitContainer["textDisplay"]).tfType as TextField;
			_tfPart = MovieClip(super._hitContainer["textDisplay"]).tfPart as TextField;
			_tfError = MovieClip(super._hitContainer["textDisplay"]).tfError as TextField;
		}
		
		private function setupButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			ButtonCreator.createButtonEntity( super._hitContainer["startCycleButton"], this, startCycle );
			ButtonCreator.addLabel( super._hitContainer["startCycleButton"], "Start Cycle", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			ButtonCreator.createButtonEntity( super._hitContainer["stopCycleButton"], this, stopCycle );
			ButtonCreator.addLabel( super._hitContainer["stopCycleButton"], "Stop Cycle", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			ButtonCreator.createButtonEntity( super._hitContainer["checkAllButton"], this, checkAll );
			ButtonCreator.addLabel( super._hitContainer["checkAllButton"], "Speed Check All", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			ButtonCreator.createButtonEntity( super._hitContainer["stepForwardBtn"], this, stepForward );
			ButtonCreator.addLabel( super._hitContainer["stepForwardBtn"], "Step Forward", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			ButtonCreator.createButtonEntity( super._hitContainer["stepBackBtn"], this, stepBack );
			ButtonCreator.addLabel( super._hitContainer["stepBackBtn"], "Step Back", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			ButtonCreator.createButtonEntity( super._hitContainer["printButton"], this, logErrors );
			ButtonCreator.addLabel( super._hitContainer["printButton"], "Log Errors", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			ButtonCreator.createButtonEntity( super._hitContainer["toggleLookTargetButton"], this, toggleLookTarget );
			ButtonCreator.addLabel( super._hitContainer["toggleLookTargetButton"], "Look Target", labelFormat, ButtonCreator.ORIENT_CENTERED );
		}
		
		private function toggleLookTarget(...args):void
		{
			if(_lookUpdateTarget == _npc)
			{
				_lookUpdateTarget = super.shellApi.player;
			}
			else
			{
				_lookUpdateTarget = _npc;
			}
			
			super._hitContainer["lookTargetText"].text = _lookUpdateTarget.get(Id).id;
		}
		
		private function setupComboBoxes():void
		{
			var partType:String;
			var partNames:Vector.<String>;
			var comboBox:ComboBox;
			for(var u : uint = 0; u < _partTypes.length; u++)
			{
				partType = _partTypes[u];
				
				comboBox = new ComboBox();
				comboBox.buttonMode = true;
				comboBox.x = 400 + u % 3 * 150;
				comboBox.y = 500 + Math.floor(u/3) * 50;
				comboBox.dropdownWidth = 100;
				comboBox.rowCount = 12;
				comboBox.name = partType;
				comboBox.addEventListener(Event.CHANGE, comboUpdate);
				super._hitContainer.addChild( comboBox );
				
				var tF : TextField = new TextField();
				tF.text = partType;
				tF.x = comboBox.x;
				tF.y = comboBox.y - 18;
				tF.height = 22;
				super._hitContainer.addChild(tF);
				
				partNames = _partDicts[partType];
				for(var v : uint = 0; v < partNames.length; v++)
				{
					comboBox.addItem({label:partNames[v]});
				}
			}
		}
		
		private function comboUpdate(e:Event):void
		{
			// update skin part based on combo box
			var comboBox:ComboBox = e.currentTarget as ComboBox;
			
			// make last selected combo box the _currentType
			_currentType = comboBox.name;
			_currentTypeIndex = _partTypes.indexOf( _currentType );
			_currentPartIndex = comboBox.selectedIndex; 

			// set skin
			setSkin();
		}
		
		private function startCycle( btnEntity:Entity = null ):void
		{
			stopCycle();
			if(_currentTypeIndex < _partTypes.length){
				_currentType = _partTypes[_currentTypeIndex];
				_halt = false;
				loadCycle();
			}
		}
		
		private function checkAll( btnEntity:Entity = null ):void
		{
			stopCycle();
			_errorLogs.length = 0;
			_currentTypeIndex = _currentPartIndex = 0;
			_currentType = _partTypes[_currentTypeIndex];
			_halt = false;
			_waitTime = 0;
			loadCycle();
		}
		
		private function stopCycle( btnEntity:Entity = null ):void
		{
			clearTimeout(_partErrorTimer);
			clearTimeout(_partCycleTimer);
			_halt = true;
		}
		
		private function stepForward(  btnEntity:Entity = null ):void
		{
			if( _currentPartIndex < _partDicts[_currentType].length - 1)
			{
				_currentPartIndex++;
			}
			setSkin();
		}

		private function stepBack(  btnEntity:Entity = null ):void
		{
			if( _currentPartIndex > 0 )
			{
				_currentPartIndex--;
			}
			setSkin();
		}
		
		private function setSkin():void
		{
			clearTimeout(_partErrorTimer);
			_partErrorTimer = setTimeout( partFailed, 1500 );
			SkinUtils.setSkinPart( _lookUpdateTarget, _currentType, _partDicts[_currentType][_currentPartIndex], true, partLoaded);
		}
		
		private function updateText( errorMessage:String = "No Error"):void
		{
			_tfType.text = _currentType;
			_tfPart.text = _partDicts[_currentType][_currentPartIndex];
			_tfError.text = errorMessage;
		}
		
		private function loadCycle():void
		{
			if(!_halt)
			{
				clearTimeout(_partErrorTimer);
				if( _currentTypeIndex < _partTypes.length )
				{
					_partErrorTimer = setTimeout( partFailedCycle, 1500 );
					SkinUtils.setSkinPart( _lookUpdateTarget, _currentType, _partDicts[_currentType][_currentPartIndex], false, partLoadedCycle);
				}
				else
				{
					trace("Batch Complete: ");
					logErrors();
				}
			}
		}
		
		private function logErrors( btnEntity:Entity = null ):void
		{
			trace("Part Errors:\n");
			if( _errorLogs.length == 0 )
			{
				trace("No Part Errors Found.");
			}
			else
			{
				_currentTypeIndex--;
				for (var i:int = 0; i < _errorLogs.length; i++) 
				{
					trace( _errorLogs[i] );
				}
			}
		}
		
		private function logError( errorMessage:String ):void
		{
			_errorLogs.push( errorMessage );
			_tfError.text = errorMessage;
		}
		
		private function partLoadedCycle(skinPart:SkinPart = null ):void
		{
			updateText();
			if( _currentPartIndex < _partDicts[_currentType].length - 1)
			{
				_currentPartIndex++;
			}
			else
			{
				_currentPartIndex = 0;
				_currentTypeIndex++;
				if( _currentTypeIndex < _partTypes.length )
				{
					_currentType = _partTypes[_currentTypeIndex];
				}
			}
			
			if( _waitTime > 0 )
			{
				clearTimeout(_partCycleTimer);
				_partCycleTimer = setTimeout(loadCycle, _waitTime);	// Don't really understand by we would wait to call loadCycle
			}
			else
			{
				loadCycle();
			}
		}
		
		private function partFailedCycle():void
		{
			updateText( "ERROR : Timed Out" );
			logError( "Timed Out on " + _partDicts[_currentType][_currentPartIndex] + " of type: " + _currentType );
			partLoadedCycle();
		}
		
		private function partLoaded(skinPart:Object):void
		{
			updateText();
			clearTimeout(_partCycleTimer);
			clearTimeout(_partErrorTimer);
		}
		
		private function partFailed():void
		{
			updateText( "ERROR : Timed Out" );
			logError( "Timed Out on " + _partDicts[_currentType][_currentPartIndex] + " of type: " + _currentType );
			clearTimeout(_partCycleTimer);
			clearTimeout(_partErrorTimer);
		}
		
		private var _lookUpdateTarget:Entity;
	}
}