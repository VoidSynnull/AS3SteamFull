package game.data.multiplayer.chat
{
	import game.scene.template.GameScene;
	
	import org.osflash.signals.Signal;
	
	public class ChatData
	{
		public static var CHAT_OPTION_TYPE_SUBJECT:int 		 = 0;
		public static var CHAT_OPTION_TYPE_MSG:int			 = 1;
		public static var CHAT_OPTION_TYPE_REPLY:int		 = 2;
		
		public function ChatData(){
			
		}
		
		public function destroy():void{
			_scene = null;
			_data = null;
		}
		
		public function loadData($scene:GameScene, $xmlURL:String):void{
			_scene = $scene;
			
			var chatXML:XML = $scene.shellApi.getFile($xmlURL);
			loaded.addOnce(loadGenChatData);
			
			if(chatXML == null)
			{
				$scene.shellApi.loadFile($xmlURL, parseData);
			}
			else
			{
				parseData(chatXML);
			}
		}
		
		private function loadGenChatData():void
		{
			// temporary 
			var url:String = _scene.shellApi.dataPrefix+"multiplayer/chat.xml";
			//var url:String = ChatData.getFullUrl(_scene, "chat_gen.xml", _scene.groupPrefix);
			var chatXML:XML = _scene.shellApi.getFile(url);
			
			if(chatXML == null)
			{
				_scene.shellApi.loadFile(url, parseData);
			}
			else
			{
				parseData(chatXML); 
			}
		}
		
		private function parseData($data:XML):void{
			for(var s:int = 0; s < $data.subject.length(); s++){
				
				var subjectId:String = $data.subject[s].@id;
				var msgs:Vector.<Object> = new Vector.<Object>();
				var replies:Vector.<Object> = new Vector.<Object>();
				
				for(var o:int = 0; o < $data.subject[s].msg.length(); o++){
					var msg:Object = {};
					msg.msg 				= $data.subject[s].msg[o];
					msg.id 					= $data.subject[s].msg[o].@id;
					
					// button data?
					if($data.subject[s].msg[o].attribute("button").length() > 0){
						msg.button = new Object();
						msg.button.label = $data.subject[s].msg[o].@button;
						msg.button.handler = $data.subject[s].msg[o].@handler;
						msg.button.param = $data.subject[s].msg[o].@param;
					}
					
					msgs[o] = msg;
				}
				
				for(var r:int = 0; r < $data.subject[s].reply.length(); r++){
					var reply:Object = {};
					reply.msg 				= $data.subject[s].reply[r];
					reply.replyId 			= $data.subject[s].reply[r].@replyId;
					reply.id = r + 1; // generate an id
					
					// button data?
					if($data.subject[s].reply[r].attribute("button").length() > 0){
						reply.button = new Object();
						reply.button.label = $data.subject[s].reply[r].@button;
						reply.button.handler = $data.subject[s].reply[r].@handler;
						reply.button.param = $data.subject[s].reply[r].@param;
					}
					
					replies[r] = reply;
				}
				
				var subIndex:int = subjectIndex(subjectId);
				if(subIndex >= 0){
					// merge current subject data to already existing subject data
					//trace(subjectId);
					msgs = mergeOptions(_data[subIndex].msgs, msgs);
					replies = mergeReplies(_data[subIndex].replies, replies);
					_data[subIndex] = {subject:subjectId, msgs:msgs, replies:replies};
					//trace("");
				} else {
					// create new data from subject object
					_data[s] = {subject:subjectId, msgs:msgs, replies:replies};
				}
			}
			
			loaded.dispatch();
		}
		
		private function mergeOptions(vec1:Vector.<Object>, vec2:Vector.<Object>):Vector.<Object>{
			var lastId:int = 0; // greatest ID in vec1
			var option:Object;
			for each(option in vec1){
				if(option.id > lastId){
					lastId = option.id;
				}
			}
			
			for each(option in vec2){
				option.id = int(option.id)+int(lastId);
			}
			
			var merge:Vector.<Object> = vec1.concat(vec2);
			
			for each(option in merge){
				//trace(" "+option.id+":"+option.msg);
			}
			
			return merge;
		}
		
		private function mergeReplies(vec1:Vector.<Object>, vec2:Vector.<Object>):Vector.<Object>{
			var lastId:int = 0; // greatest ID in vec1
			var lastReplyId:int = 0;
			var reply:Object;
			
			for each(reply in vec1){
				if(reply.id > lastId){
					lastId = reply.id;
				}
				if(reply.replyId > lastReplyId){
					lastReplyId = reply.replyId;
				}
			}
			
			for each(reply in vec2){
				reply.id = int(reply.id) + int(lastId);
				reply.replyId = int(reply.replyId) + int(lastReplyId);
			}
			
			var merge:Vector.<Object> = vec1.concat(vec2);
			
			for each(reply in merge){
				//trace(" "+reply.id+":"+reply.replyId+":"+reply.msg);
			}
			
			return merge;
		}
		
		private function subjectIndex($subjectId:String):int{
			// returns the index of the subject in the data
			try{
				for(var c:int = 0; c < _data.length; c++){
					if(_data[c].subject == $subjectId)
						return c;
				}
			} catch(e:Error){
				trace(e.getStackTrace());
			}
			
			return -1;
		}
		
		private function randomize(a:*, b:*):int{
			return( Math.random() > .5) ? 1: -1;
		}
		
		public function getObject($subject:int, $index:int, $type:int):Object{
			var data:Object = _data[$subject];
			if($type == CHAT_OPTION_TYPE_MSG){
				for each(var msg:Object in data.msgs){
					if(msg.id == $index){
						return msg;
					}
				}
			} else {
				for each(var reply:Object in data.replies){
					if(reply.id == $index){
						return reply;
					}
				}
			}
			
			return {};
		}
		
		public function get data():Vector.<Object>{
			// randomize msgs
			for each(var obj:Object in _data){
				obj.msgs = obj.msgs.sort(randomize);
			}
			
			return _data;
		}
		
		public var loaded:Signal = new Signal();
		public var _data:Vector.<Object> = new Vector.<Object>();
		
		private var _scene:GameScene;
		
		/////////////////////////////// static methods ///////////////////////////////
		
		
		public static function getFullUrl(_scene:GameScene, url:String, prefix:String = ""):String
		{
			var fullUrl:String;
			var typePrefix:String = _scene.shellApi.assetPrefix;
			
			if (String(url).indexOf(".xml") > -1)
			{
				typePrefix = _scene.shellApi.dataPrefix;
			}
			
			if(url.indexOf(typePrefix) > -1)
			{
				// if it has the type path in the url, assume it is an absolute url
				fullUrl = url;
			}
			else
			{
				fullUrl = typePrefix + prefix + url;
			}
			
			return(fullUrl);
		}
	}
}