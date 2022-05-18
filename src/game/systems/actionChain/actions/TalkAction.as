package game.systems.actionChain.actions
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.data.scene.characterDialog.DialogData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;

	// Make char entity talk using a dialog ID or actual text string
	public class TalkAction extends ActionCommand
	{
		private var say_id:String;
		private var directSay:Boolean;
		private var end_id:String;
		private var _char:*;
		
		private var _sayArray:Array = [];
		
		private var talkCallback:Function;

		private var _talkHeight:Number = 0;
		/**
		 * Make char entity talk using a dialog ID or actual text string
		 * @param char				Entity to talk
		 * @param say_id			Dialog ID or actual dialog text (If string contains "|", then it will be converted to an array where a dialog string will be pulled at random)
		 * @param directSayText		If true, then say_id is actually a dialog string that the character will say directly.
		 * @param end_id			If you have a chain of dialogs and you want to listen for a different id to end with.
		 */
		public function TalkAction( char:*, say_id:String, directSayText:Boolean = false, end_id:String = null, talkHeight:Number=0 )
		{
			//entity = char;
			_char = char;
			_talkHeight = talkHeight;
			
			this.say_id = say_id;			
			this.directSay = directSayText;
			this.end_id = end_id;
		
			
			if(!this.end_id) this.end_id = say_id;
			
			// if direct text, then parse
			if (directSayText)
				_sayArray = say_id.split("|");
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			talkCallback = callback;
			
			if(_char is String)
			{
				entity = group.shellApi.currentScene.getEntityById(_char);
			}
			else
				entity = _char;
			
			if (entity == null)
				return;
			
			var dialog:Dialog = entity.get( Dialog );
			if ( dialog == null )
			{
				talkCallback();
				talkCallback = null;
				return;
			}
			if(_talkHeight != 0)
				dialog.dialogPositionPercents = new Point(1, _talkHeight);
			// if not direct say, then trigger dialog by id
			if ( !directSay )
				dialog.sayById( say_id );
			else
			{
				// if direct say
				var len:int = _sayArray.length;
				
				// if only one, the say it
				if (len == 1)
				{
					dialog.say( say_id );
				}
				else
				{
					// if more than one, then get random dialog text
					var num:int = Math.floor(len * Math.random());
					dialog.say( _sayArray[num] );
				}
			}

			dialog.complete.add( dialogCompleted );
		}
		
		private function dialogCompleted(data:DialogData):void
		{
			if(data.id == end_id || data.event == end_id || directSay)
			{
				entity.get(Dialog).complete.remove(dialogCompleted);
				talkCallback();
				talkCallback = null;
			}
		}
	}
}