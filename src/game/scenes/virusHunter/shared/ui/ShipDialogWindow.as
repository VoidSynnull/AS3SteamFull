package game.scenes.virusHunter.shared.ui
{
	import flash.display.DisplayObjectContainer;
	import flash.text.StyleSheet;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.managers.SoundManager;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.entity.character.Talk;
	import game.data.TimedEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.ui.popup.CharacterDialogWindow;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class ShipDialogWindow extends CharacterDialogWindow
	{
		public function ShipDialogWindow(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function loaded():void
		{		
			super.loaded();
			
			var animationEntity:Entity = TimelineUtils.convertClip(super.screen, this);
			_animationTimeline = animationEntity.get(Timeline);
			_animationTimeline.labelReached.add(handleLabelReached);
			var graphicsEntity:Entity = TimelineUtils.convertClip(super.screen.shipText, this, null, animationEntity);
			_graphicsTimeline = graphicsEntity.get(Timeline);
		}
		
		public function playShipMessage(dialogId:String, useCharacter:Boolean = true, graphicsFrame:String = null, characterId:String = null, openWindow:Boolean = true):void
		{
			if(graphicsFrame && _graphicsTimeline)
			{
				_graphicsTimeline.gotoAndStop(graphicsFrame);
			}
			
			if(characterId)
			{
				_currentCharacterId = characterId;
				
				/**
				 * Drew Martin
				 * 
				 * Addd this check, since it seems like charEntity is turning up null.
				 */
				if(super.charEntity)
				{
					if(super.charEntity.get(Id).id != characterId)
					{
						charEntity = super.getEntityById( characterId );
					}
				}
			}
			
			_showCharacter = useCharacter;
			
			super.playMessage(dialogId, openWindow, true);
			// remove StyleSheet so we can adjust the textField
			super.textField.styleSheet = null;
			super.textField.wordWrap = true;
			
			if(!useCharacter)
			{
				super.textField.x = -20;
				// reposition textField y so it isn't dropped down so far; no idea why it insists on doing this with HTML
				super.textField.y = -20;
				// can't change default textFormat with a styleSheet so overwrite it
				super.textField.defaultTextFormat = SHIP_TEXT;
				
				super.textField.height = 100;
				
				/**
				 * Drew Martin
				 * 
				 * Added this check as well.
				 */
				if(charEntity)
				{
					Sleep(charEntity.get(Sleep)).sleeping = true;
				}
				
				_nonCharacterDialog = super.allDialogData[_currentCharacterId][dialogId];
			}
			else
			{
				super.textField.x = 70;
				// reposition textField y so it isn't dropped down so far; no idea why it insists on doing this with HTML
				super.textField.y = 15;
				// can't change default textFormat with a styleSheet so overwrite it
				super.textField.defaultTextFormat = CHARACTER_TEXT; 
			}
			
			super.textField.styleSheet = STYLE_SHEET;
		}

		override protected function triggerDialogue():void
		{
			if(_showCharacter)
			{
				super.triggerDialogue();
			}
			else
			{
				super.showDialog(_nonCharacterDialog);
			}
		}
		
		override protected function onDialogComplete(dialog:DialogData = null):void
		{
			if(_showCharacter)
			{
				var talk:Talk = Talk(charEntity.get(Talk));
				talk.isEnd = true;
			//	charEntity.get( Talk )
			//	super.onDialogComplete( dialog );
				SceneUtil.addTimedEvent(this, new TimedEvent( 1, 1, closeMessage ));
			//	super.closeMessage();//super.updateTalkAnimation(false);
			}
			
			if(dialog.link != null)
			{
				this.playShipMessage(dialog.link, _showCharacter, null, null, false);
			}
			else
			{
				super.closeMessage();
			}
		}
		
		override protected function openTransition():void
		{
			if( !super.isOpened )
			{
				super.hide(false);
				super._isOpen = true;
				//super.shellApi.soundManager.play( SoundManager.EFFECTS_PATH + MESSAGE_WINDOW );
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + MESSAGE_WINDOW);
				_animationTimeline.reverse = false;
				_animationTimeline.gotoAndPlay("begin");
			}
			else
			{
				if(!_animationTimeline.reverse)
				{
					triggerDialogue();
				}
			}
		}

		override protected function closeTransition():void
		{
			if( super.isOpened )
			{
				_animationTimeline.reverse = true;
				_animationTimeline.gotoAndPlay("end");
				//super.shellApi.soundManager.play( SoundManager.EFFECTS_PATH + MESSAGE_WINDOW );
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + MESSAGE_WINDOW);
			}
			else
			{
				super.messageClose(true);
			}
			
			super._isOpen = false;
		}
		
		private function handleLabelReached(label:String):void
		{
			if(label == "end")
			{
				if(!_animationTimeline.reverse)
				{
					this.triggerDialogue();
				}
			}
			else if(label == "begin" && _animationTimeline.reverse)
			{
				super.messageClose(true);
			}
		}
				
		private const MESSAGE_WINDOW:String = "tutorial_box.mp3";
		private const SHIP_TEXT:TextFormat = new TextFormat( "Futura", 18, 0xffffff, "bold", false, false, null, null, "center", null, 0, null, 0 );
		private const CHARACTER_TEXT:TextFormat = new TextFormat( "CreativeBlock BB", 16, 0xffffff, false, false, null, null, null, "left", null, 10, null, 0 );
		private const STYLE_SHEET:StyleSheet = new ShipStyleSheet() as StyleSheet;
		
		private var _animationTimeline:Timeline;
		private var _graphicsTimeline:Timeline;
		private var _showCharacter:Boolean = false;
		private var _nonCharacterDialog:DialogData;
		private var _currentCharacterId:String;
	}
}