package game.ui.multiplayer.chat
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.components.multiplayer.chat.MsgBalloon;
	import game.util.EntityUtils;

	public class MsgBalloonCreator
	{
		public function MsgBalloonCreator(group:Group, clip:MovieClip)
		{
			_group = group;
			_clip = clip;
		}
		
		public function create():Entity{
			_entity = new Entity();
			
			_entity = EntityUtils.createSpatialEntity(_group, _clip);
			var msgBalloon:MsgBalloon = new MsgBalloon();
			msgBalloon.updated.add(updateMsgBalloon);
			_entity.add(msgBalloon);
			
			var textFormat:TextFormat	= new TextFormat();
			textFormat.align 			= TextFormatAlign.CENTER;
			textFormat.bold 			= true;
			textFormat.font 			= "CreativeBlock BB";
			textFormat.size 			= 24;
			textFormat.color 			= 0x000000;
			
			_msgText = new TextField();
			_msgText.width = Chat.CHAT_TEXT_WIDTH;
			_msgText.height = 25;
			_msgText.setTextFormat(textFormat);
			_msgText.defaultTextFormat = textFormat;
			_msgText.embedFonts 		= true;
			_msgText.antiAliasType 		= AntiAliasType.NORMAL;
			_msgText.autoSize			= TextFieldAutoSize.CENTER;
			_msgText.wordWrap 			= true;
			_msgText.multiline 			= true;
			_msgText.maxChars 			= 0;
			_msgText.text = "";
			_msgText.mouseEnabled = false;
			_msgText.mouseWheelEnabled = false;
			_msgText.x = - _msgText.width * 0.5;
			
			_clip.addChild(_msgText);
			
			return _entity;
		}
		
		private function updateMsgBalloon($msgBalloon:MsgBalloon):void
		{
			// hide content (until it's ready)
			Display(_entity.get(Display)).visible = false;
			
			// populate text into msgBalloon
			if($msgBalloon.msg){
				_msgText.text = $msgBalloon.msg;
				
				// scale bg
				var bg:MovieClip = Display(_entity.get(Display)).displayObject["bg"];
				bg.height = _msgText.height + Chat.CHAT_TEXT_Y_BUFFER;
				
				// allign text to bg
				_msgText.y = ((bg.height-Chat.CHAT_BUBBLE_SHADOW_HEIGHT) * 0.5) - (_msgText.height * 0.5);
				
				// flush top edge of background
				var bounds:Rectangle = bg.getBounds(Display(_entity.get(Display)).displayObject);
				bg.y = bg.y - bounds.y;
			}
		}
		
		private var _entity:Entity;
		
		private var _clip:MovieClip;
		private var _group:Group;
		
		private var _msgText:TextField;
	}
}