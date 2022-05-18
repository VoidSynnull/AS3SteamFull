package game.components.entity
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import game.data.scene.characterDialog.DialogData;
	
	import org.osflash.signals.Signal;
	
	public class Dialog extends Component
	{
		public static const MIN_DIALOG_SPEED:Number		= 0.5;	// this is the fastest speed
		public static const DEFAULT_DIALOG_SPEED:Number	= 0.5;	// was 2.0
		public static const MAX_DIALOG_SPEED:Number		= 3;	// this is the slowest speed
		
		public var allDialog:Dictionary;			// Dictionary of all dialog for a single character within a scene, uses ids or events as keys
		public var current:*;						// currently active dialog
		public var complete:Signal = new Signal(DialogData);
		public var start:Signal = new Signal(DialogData);
		public var speaking:Boolean = false;
		public var faceSpeaker:Boolean = true;
		public var dialogPositionPercents:Point; 	// used to position of wordballoon, x = % of bounds width, y = % of bounds height
		public var allowOverwrite:Boolean = true; 	// set tp true if you want new statements to overwrite current ones.
		public var initiated:Boolean = false;  		// set to true when another character (usually player) initiates dialog by clicking on an npc.
		//public var balloonTarget:Spatial;
		public var blockTriggerEvents:Boolean = false;	// flag to allow for triggered events to be ignore, necessary in a few edge cases
		public var stoppedToListen:Boolean;
		override public function destroy():void
		{
			complete.removeAll();
			start.removeAll();
			
			super.destroy();
		}
		
		private var _container:DisplayObjectContainer;
		
		/**
		 * A container for manually placing dialog/word balloons in a specific container. CharacterDialogView makes too many assumptions about where
		 * word balloons should ultimately go. With this, you can manually specify what container you'd like your dialog to appear. If left as null,
		 * CharacterDialogView will place word balloons in its groupContainer.
		 * @author: Drew Martin
		 */
		public function get container():DisplayObjectContainer
		{
			return this._container;
		}
		
		public function set container(container:DisplayObjectContainer):void
		{
			this._container = container;
		}
		
		// FOR USE BY SYSTEMS ONLY
		public var _sayCurrent:Boolean = false;	// flag, if true current will be displayed, then set back to false
		public var _manualSay:*;				// if not null, will be displayed, then set back to null. Can be DialogData or String
		private var _removedEvent:String;
		private var _balloonPath:String = "ui/elements/wordBalloon.swf";
		private var _wordBalloonPath:String = "ui/elements/wordBalloon.swf";
		private var _thoughtBalloonPath:String = "ui/elements/thoughtBalloon.swf";

		/**
		 * A handler listening to ShellApi's eventTrigger updates, receives latest events
		 * @param	event - recently triggered event
		 * @param   makeCurrent - should this be saved as the current data or simply triggered.
		 * @param	init - This is set to true ONLY for initial setup to get the latest event set to current after load and suppress triggering 'triggeredByEvent' dialog.
		 * @param   removeEvent - IF this event is getting removed, the current will need to get rest if it matches this event.      
		 */
		public function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(this.allDialog != null && !blockTriggerEvents)
			{
				var eventDialog:* = this.allDialog[event];
				
				if(eventDialog != null)	// check to see if there is corresponding dialog for this event
				{
					// store this as the current dialog if we're saving
					if(makeCurrent)
					{
						if(this.current)// current was undefined upon replaying an island which meant that this.current.event was causing issues
						{
							if(removeEvent == null || removeEvent == this.current.event || (_removedEvent != null && _removedEvent != eventDialog.event))
							{
								if(removeEvent != null)
								{
									// we store the event which caused this dialog to be removed so subsequent dialog triggers can overwrite the current as long as they don't match the removed event.
									if(removeEvent == this.current.event)
									{
										_removedEvent = removeEvent;
									}
								}
								
								if(!init || init && eventDialog.triggeredByEvent != event)
								{
									this.current = eventDialog;
								}
							}
						}
						else
						{
							if(!init || init && eventDialog.triggeredByEvent != event)
							{
								this.current = eventDialog;
							}
						}
						if(removeEvent == null)
						{
							_removedEvent = null;
						}
					}
					
					// if this also matches the 'triggeredByEvent' say the dialog now.
					if(eventDialog.triggeredByEvent == event && removeEvent == null && !init)
					{
						if(makeCurrent)
						{
							_sayCurrent = true;
						}
						else
						{
							_manualSay = eventDialog;
						}
					}
				}
			}
		}
		
		/**
		 * To set a new word balloon, such as a spikey computerized one.
		 */
		public function set balloonPath( path:String ):void
		{
			_balloonPath = path;
		}
		
		/**
		 * To set a thought balloon
		 */
		public function setThoughtBalloon():void
		{
			_balloonPath = _thoughtBalloonPath;
		}
		
		/**
		 * To reset back to word balloon
		 */
		public function resetBalloon():void
		{
			_balloonPath = _wordBalloonPath;
		}
		
		/**
		 * To get the word balloon path.
		 */
		public function get balloonPath():String
		{
			return _balloonPath;
		}
		/**
		 * Returns DialogData or String (in case of statement) corresponding to id.
		 * Identifier can be the id or an event if there is no id.
		 * @param	identifier
		 * @return
		 */
		public function getDialog(identifier:String):*
		{
			if(this.allDialog != null)
			{
				return(this.allDialog[identifier]);
			}
			
			return(null);
		}
		
		/**
		 * Manually say a statement.
		 * @param	dialog - Can be DialogData or a String (In case of a statement)
		 */
		public function say(dialog:*):void
		{
			_manualSay = dialog;
		}
		
		/**
		 * Say the current dialog
		 */
		public function sayCurrent():void
		{
			_sayCurrent = true;
		}
		
		/**
		 * Manually say one of the available dialogs
		 * @param	id
		 */
		public function sayById(id:String):void
		{
			_manualSay = getDialog(id);
		}
		
		/**
		 * Set specified dialog to be current.
		 * @param	id
		 */
		public function setCurrentById(id:String):void
		{
			this.current = getDialog(id);
		}
		
		/**
		 * Searches through all dialog Strings and replaces specific a <code>keyword</code> - such as [PlayerName] or [Island] - 
		 * with a <code>replacement</code> word.
		 */
		public function replaceKeyword(keyword:String, replacement:String):void
		{
			for(var id:String in this.allDialog)
			{
				var dialog:* = this.allDialog[id];
				
				if(dialog is DialogData)
				{	
					DialogData(dialog).dialog = DialogData(dialog).dialog.replace(keyword, replacement);
				}
				else if(dialog is String)
				{	
					this.allDialog[id] = String(dialog).replace(keyword, replacement);
				}
			}
		}
	}
}