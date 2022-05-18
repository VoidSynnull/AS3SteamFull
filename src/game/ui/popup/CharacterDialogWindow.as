package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Talk;
	import game.components.scene.SceneInteraction;
	import game.components.ui.ToolTip;
	import game.creators.ui.WordBalloonCreator;
	import game.data.TimedEvent;
	import game.data.game.GameData;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.util.DataUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;


	public class CharacterDialogWindow extends Popup
	{
		public function CharacterDialogWindow(container:DisplayObjectContainer=null)
		{
			super(container);
			this.messageComplete = new Signal();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{	
			super.init(container);
			super._defaultCursor = null;
			
			load();
		}
		
		public function configData( groupPrefix:String = "", screenAsset:String = "", useLocalNpcs:Boolean = true, useLocalDialog:Boolean = true ):void
		{	
			super.groupPrefix = groupPrefix;
			super.screenAsset = screenAsset;
			this.useLocalNpcs = useLocalNpcs;
			this.useLocalDialog = useLocalDialog;
		}
		
		override public function destroy():void
		{
			_characterDialogGroup = null;
			_charEntity = null;
			_currentDialogEvent = null;
			_dialogTimedEvent = null;
			_textField = null;
			SceneUtil.getDialogComplete(this).remove(onDialogComplete);
			
			super.destroy();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			var assets:Array = [];
			
			if( DataUtils.validString( super.screenAsset ) )
			{
				assets.push( super.screenAsset );
			}
			if( this.useLocalNpcs )
			{
				assets.push( GameScene.NPCS_FILE_NAME );
			}
			if( this.useLocalDialog )
			{
				assets.push( GameScene.DIALOG_FILE_NAME );
			}
			
			if( assets.length > 0 )
			{
				super.shellApi.fileLoadComplete.addOnce(loaded);
				super.loadFiles( assets );
			}
			else
			{
				loaded();
			}
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.preparePopup(); // popup specific preparation
				
			// create character
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.addToolTips = false;
			
			var charContainer:DisplayObjectContainer = super.groupContainer;
			if( super.screen )
			{
				charContainer = super.screen;
				super.screen.mouseChildren = false;
				super.screen.mouseEnabled = false;
			}
			// load the characters into the the groupContainer instead of the hitContainer since this isn't a platformer scene with camera layers.
			if( this.useLocalNpcs )
			{
				characterGroup.setupGroup(this, charContainer, super.getData( GameScene.NPCS_FILE_NAME ), onCharactersLoaded );
			}
			
			// create/retrieve character dialog
			// NOTE :: must create CharacterGroup before CharacterDialogGroup
			if( this.useLocalDialog )
			{
				_characterDialogGroup = new CharacterDialogGroup();
				_characterDialogGroup.setupGroup(this, super.getData( GameScene.DIALOG_FILE_NAME ), charContainer);
			}
			else
			{
				_characterDialogGroup = super.parent.getGroupById( CharacterDialogGroup.GROUP_ID ) as CharacterDialogGroup;
				if( _characterDialogGroup == null )
				{
					_characterDialogGroup = new CharacterDialogGroup();
					_characterDialogGroup.setupGroup( shellApi.currentScene, shellApi.currentScene.getData(shellApi.currentScene.groupPrefix + GameScene.DIALOG_FILE_NAME), charContainer);
				}
			}
	
			this.allDialogData = _characterDialogGroup.allDialogData;
			SceneUtil.getDialogComplete(this).add( onDialogComplete );
		}

		/**
		 * Handles character load complete 
		 */
		protected function onCharactersLoaded():void
		{
			super.groupContainer.mouseChildren = false;
			super.groupContainer.mouseEnabled = false;
			super.container.mouseEnabled = false;
			
			super.groupReady();
		}

		/**
		 * Adjust the position, scale, and container of a character.
		 */
		public function adjustChar( charId:String, charContainer:DisplayObjectContainer = null, position:Point = null, scale:Number = NaN, makeSleep:Boolean = true):void
		{
			// setup character
			_charEntity = super.getEntityById( charId );
			
			if(_charEntity == null)
			{
				return;
			}
			
			if( charContainer )
			{
				Display(_charEntity.get(Display)).setContainer( charContainer );
			}
			else
			{
				Display(_charEntity.get(Display)).setContainer( super.screen );
			}
			
			var spatial:Spatial = _charEntity.get(Spatial);
			if( position )
			{
				spatial.x = position.x;
				spatial.y = position.y;
			}
			if( !isNaN(scale) )
			{
				spatial.scale = scale;
			}
			
			if(makeSleep)
			{
				var sleep:Sleep = _charEntity.get(Sleep);
				if( sleep == null )
				{
					sleep = new Sleep();
					_charEntity.add( sleep );
				}
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;
			}
			
			// assign dialog
			_characterDialogGroup.assignDialog( _charEntity );
			
			_charEntity.remove(Interaction);
			_charEntity.remove(ToolTip);
			_charEntity.remove(SceneInteraction);
		}
		
		/**
		 * Add/assign a textField, with the option of specifying its position and container.
		 */
		public function assignTextField( tf:TextField = null, textContainer:DisplayObjectContainer = null, position:Point = null ):void
		{
			if( tf )
			{
				_textField = tf;
			}
			
			if( _textField )
			{
				if( textContainer )
				{
					textContainer.addChild( _textField );
				}

				if( position )
				{
					_textField.x = position.x;
					_textField.y = position.y;
				}
			}
		}
		
		/**
		 * Play a dialog message by id, and manage whether window opens, closes, or is removed on completion.
		 */
		public function playMessage( dialogId:String, openWindow:Boolean = true, closeOnComplete:Boolean = false, removeOnComplete:Boolean = false ):void
		{
			if(_textField)
			{
				if(_charEntity) 
				{ 
					Sleep(_charEntity.get(Sleep)).sleeping = false; 
					
					var dialog:Dialog = _charEntity.get(Dialog) as Dialog;
					var dialogData:DialogData = DialogData(dialog.getDialog( dialogId ));
					
					if(dialogData == null)
					{
						closeMessage();
						return;
					}
				}	// make sure entity is not sleeping
				
				_textField.text = "";	// clear textField
				//TextUtils.verticalAlignTextField(_textField);
				
				_currentDialogEvent = dialogId;
				_closeOnComplete = closeOnComplete;
				_removeOnComplete = removeOnComplete;
				
				if( openWindow && !super.isOpened )
				{
					openTransition();
				}
				else
				{
					triggerDialogue();
				}
			}
		}
		
		/**
		 * This can be overridden if a unique transition ( like a timeline ) is necessary.
		 * By default it relies on the transitions inhereted from Popup.
		 */
		protected function openTransition():void
		{
			if( !super.isOpened )
			{
				super.open(triggerDialogue);
			}
			else
			{
				triggerDialogue();
			}
		}
		
		/**
		 * This can be overridden if a unique transition ( like a timeline ) is necessary.
		 * By default it relies on the transitions inhereted from Popup.
		 */
		protected function closeTransition():void
		{
			if( super.isOpened )
			{
				super.close( _removeOnComplete, messageClose );
			}
			else
			{
				messageClose();
				if( _removeOnComplete )
				{
					super.remove();
				}
			}
		}

		protected function triggerDialogue():void
		{
			if(_charEntity)
			{
				Sleep(_charEntity.get(Sleep)).sleeping = false;
				
				var dialog:Dialog = _charEntity.get(Dialog) as Dialog;
				dialog.allowOverwrite = true;
				var dialogData:DialogData = DialogData(dialog.getDialog( _currentDialogEvent ));
				//dialog.sayById( _currentDialogEvent );
				
				var talk:Talk = _charEntity.get(Talk);
				if( talk != null )
				{
					talk.isStart = true;
				}
				
				showDialog(dialogData);
			}
		}
		
		protected function showDialog(dialogData:DialogData):void
		{
			if(_dialogTimedEvent!= null) { _dialogTimedEvent.stop(); }
			
			_textField.htmlText = dialogData.dialog;
			
			var time:Number = dialogData.timeOverride;
			
			if(isNaN(time))
			{
				time = WordBalloonCreator.getDialogTime(dialogData.dialog, super.shellApi.profileManager.active.dialogSpeed);
			}
			
			_dialogTimedEvent = SceneUtil.addTimedEvent(this, new TimedEvent(time, 1, Command.create(onDialogComplete, dialogData)));
		}
		
		protected function onDialogComplete(dialog:DialogData = null):void
		{
			if( _charEntity != null )
			{
				var talk:Talk = _charEntity.get(Talk);
				if( talk != null )
				{
					talk.isEnd = true;
				}
			}
			
			if(dialog.link != null)
			{
				playMessage(dialog.link, false, true);
			}
			else
			{
				closeMessage();
			}
		}
		
		protected function closeMessage():void
		{			
			_textField.text = "";	// clear textField
			
			if( _removeOnComplete || _closeOnComplete )
			{
				closeTransition();
			}
			else
			{
				messageClose(true);
			}
		}
		
		protected function messageClose( makeSleep:Boolean = true ):void
		{
			if( makeSleep )
			{
				if( _charEntity != null )
				{
					var sleep:Sleep = _charEntity.get(Sleep);
					if( sleep == null )
					{
						sleep = new Sleep()
						_charEntity.add( sleep );
					}
					sleep.sleeping = true;
				}
			}
			
			this.messageComplete.dispatch();
		}
		
		/**
		 * Signal dispatched when message has completed 
		 */
		public var messageComplete:Signal;	
		
		private var _currentDialogEvent:String;
		private var _closeOnComplete:Boolean = false;
		private var _removeOnComplete:Boolean = false;
		private var _characterDialogGroup:CharacterDialogGroup;
		
		public var useLocalDialog:Boolean = true;
		public var useLocalNpcs:Boolean = true;
		public var dataPrefix:String = "";
		protected var allDialogData:Dictionary;
		
		private var _charEntity:Entity;
		public function get charEntity():Entity { return _charEntity; }
		public function set charEntity(entity:Entity):void { _charEntity = entity; }
		
		private var _textField:TextField;
		public function get textField():TextField 			{ return _textField; }
		public function set textField(tf:TextField):void 	{ _textField = tf; }
		public function get currentDialogEvent():String { return(_currentDialogEvent); }
		public function set currentDialogEvent(currentDialogEvent:String):void { _currentDialogEvent = currentDialogEvent; }
		private const TALK_DELAY:int = 90;
		private var _dialogTimedEvent:TimedEvent;
	}
}