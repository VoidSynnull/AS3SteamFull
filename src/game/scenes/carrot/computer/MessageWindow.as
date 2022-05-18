package game.scenes.carrot.computer
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.timeline.Timeline;
	import game.data.scene.characterDialog.DialogData;
	import game.ui.popup.CharacterDialogWindow;
	import game.util.TimelineUtils;

	/**
	 * ...
	 * @author Bard
	 * 
	 * DrHareMessage.
	 * Dr. Hare's head appears on the screen and says things when you hit an asteroid.
	 */
	
	public class MessageWindow extends CharacterDialogWindow
	{
		public function MessageWindow(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function loaded():void
		{	
			super.loaded();

			var animationEntity:Entity = TimelineUtils.convertClip( super.screen.content, this );
			_animationTimeline = animationEntity.get( Timeline );
			_animationTimeline.labelReached.add( handleLabelReached );
			
			super._isOpen = false;
		}
		
		override protected function triggerDialogue():void
		{
			super.triggerDialogue();
		}
		
		override protected function onDialogComplete( dialog:DialogData = null ):void
		{
			//super.updateTalkAnimation( false );
			closeMessage();
		}
		
		override protected function openTransition():void
		{
			if( !super.isOpened )
			{
				super.hide( false );
				super._isOpen = true;
				_animationTimeline.gotoAndPlay( "open" );
			}
			else
			{
				if( !_animationTimeline.reverse )
				{
					triggerDialogue();
				}
			}
		}
		
		override protected function closeTransition():void
		{
			if( super.isOpened )
			{
				_animationTimeline.gotoAndPlay( "close" );
			}
			else
			{
				super.messageClose(true);
			}
			
			super._isOpen = false;
		}
		
		private function handleLabelReached(label:String):void
		{
			if( label == "opened" )
			{
				super.charEntity.get( Display ).visible = true;
				triggerDialogue();
			}
			if( label == "close" )
			{
				super.charEntity.get( Display ).visible = false;
			}
			if( label == "closed" )
			{
				super.messageClose(true);
			}
		}

		private var _animationTimeline:Timeline;
		//private var _currentDialogEvent:String;
	}
}