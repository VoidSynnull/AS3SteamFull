package game.components.multiplayer.chat
{
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.data.ISFSArray;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSArray;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import ash.core.Component;
	
	import game.ui.multiplayer.chat.Chat;
	import game.util.PlatformUtils;
	
	import org.osflash.signals.Signal;
	
	public class MenuBalloon extends Component
	{
		public var updated:Signal = new Signal(MenuBalloon);		
		public var data:Vector.<Object>;
		public var stored:Vector.<Object>;
		public var isCategoryMenu:Boolean;
		private var _removeFirstElement:Boolean;
		
		public function MenuBalloon(smartFox:SmartFox):void
		{
			_smartFox = smartFox;
			_smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onSFSExtension);
		}
		
		/**
		 * Retrieves default chat categories
		 * @param keywords - additional keywords for altered categories
		 */
		public function getCategories(keywords:Array = null):void
		{
			var obj:ISFSObject = new SFSObject();
			if(keywords)
				obj.putSFSArray(Chat.KEY_CHAT_KEYWORDS, SFSArray.newFromArray(keywords));

			_smartFox.send(new ExtensionRequest(Chat.CMD_GET_CHAT, obj, _smartFox.lastJoinedRoom));
		}
		
		/**
		 * Retrieves 3 random messages per selected keyword(category)
		 * @param keywordID - the keyword identifier
		 */
		public function getMessages(keywordID:int,removeFirstElement:Boolean=false):void
		{
			if(removeFirstElement == true && keywordID == 2)
				_removeFirstElement = removeFirstElement;
			else
				_removeFirstElement = false;
			
			var obj:ISFSObject = new SFSObject();
			obj.putInt(Chat.KEY_CHAT_CATEGORY_ID, keywordID);
			_smartFox.send(new ExtensionRequest(Chat.CMD_GET_MESSAGES, obj, _smartFox.lastJoinedRoom));
		}
		
		/**
		 * Retrieves all replies linked to the messageID
		 * @param messageID - the message identifier
		 */
		public function getReplies(messageID:int):void
		{
			var obj:ISFSObject = new SFSObject();
			obj.putInt(Chat.KEY_CHAT_MESSAGE_ID, messageID);
			
			_smartFox.send(new ExtensionRequest(Chat.CMD_GET_REPLIES, obj, _smartFox.lastJoinedRoom));
		}
		
		/**
		 * Retrieves stored data from the previous menu
		 */
		public function back():void{
			data = stored;
			updated.dispatch(this);
		}
		
		private function onSFSExtension($event:SFSEvent):void
		{
			switch($event.params.cmd){
				case Chat.CMD_GET_CHAT:
					parseCategories($event.params.params as ISFSObject);
					break;
				case Chat.CMD_GET_MESSAGES:
					parseMessages($event.params.params as ISFSObject,_removeFirstElement);
					break;
				case Chat.CMD_GET_REPLIES:
					parseMessages($event.params.params as ISFSObject,false);
					break;
			}
		}
		
		private function parseCategories($isfso:ISFSObject):void
		{
			data = new Vector.<Object>();
			var sfsArray:ISFSArray = $isfso.getSFSArray(Chat.KEY_CHAT_CATEGORIES);
			for(var c:int = 0; c < sfsArray.size(); c++){
				var obj:ISFSObject = sfsArray.getSFSObject(c);
				data.push({string:obj.getUtfString("chat_keyword_name"), id:obj.getInt("chat_keyword_id")});
			}
			stored = data;
			updated.dispatch(this);
		}
		
		private function parseMessages($isfso:ISFSObject, removeFirstElement:Boolean):void
		{
			data = new Vector.<Object>();
			var sfsArray:ISFSArray = $isfso.getSFSArray(Chat.KEY_CHAT_MESSAGES);
			for(var c:int = 0; c < sfsArray.size(); c++){
				var obj:ISFSObject = sfsArray.getSFSObject(c);
				data.push({string:obj.getUtfString("chat_message"), id:obj.getInt("chat_message_id")});
			}
			if(removeFirstElement)
			{
				data.removeAt(0);
			}
			updated.dispatch(this);
		}

		private var _smartFox:SmartFox;
		
		
		public override function destroy():void
		{
			_smartFox.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onSFSExtension);
			_smartFox = null;
			data = null;
			stored = null;
			updated = null;
			super.destroy();
		}
	}
}