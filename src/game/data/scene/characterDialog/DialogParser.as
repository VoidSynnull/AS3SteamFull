/**
 * Parses XML with scene data.
 */

package game.data.scene.characterDialog
{
	import flash.utils.Dictionary;
	
	import engine.group.Group;
	
	import game.data.game.GameEvent;
	import game.managers.LanguageManager;
	import game.util.DataUtils;
	import game.util.SkinUtils;

	/**
	 * Parses a scene's dialog xml.
	 */
	public class DialogParser
	{
		private var _group:Group;
		private var _scene:String;

		public function DialogParser(group:Group)
		{
			this._group = group;
			var scene:String = this._group.shellApi.sceneName;
			this._scene = scene.slice(0, 1).toLowerCase() + scene.slice(1);
		}

		/**
		 * Parses a scene's dialog xml.
		 * Returns a Dictionary of (using character ids as keys) Dictionaries of Conversations, DialogData, and/or Strings for each character, using their id as the key,
		 *
		 * @param	xml
		 * @return
		 */
		public function parse(xml:XML):Dictionary
		{
			var data:Dictionary = new Dictionary(true);
			var characters:XMLList = xml.children() as XMLList;
			var dialogs:XMLList;
			var characterID:String;

			for (var i:uint = 0; i < characters.length(); i++)
			{
				dialogs = characters[i].children();
				characterID = characters[i].attribute("id");	// id should be the character's id
				data[characterID] = new Dictionary();

				for (var n:uint = 0; n < dialogs.length(); n++)
				{
					parseDialog(dialogs[n], data[characterID], characterID);
				}
			}

			return(data);
		}

		/**
		 *
		 * @param	xml - dialog XML for a single character within a scene
		 * @param	data - dictionary for a single character within a scene, stores DialogData
		 * @param	entityID - id of character
		 */
		private function parseDialog(xml:XML, data:Dictionary, entityID:String):void
		{
			var dialogType:String = String(xml.name());
			var key:String;
			
			if(dialogType == CONVERSATION)
			{
				parseConversation(xml, data, entityID);
			}
			else if(dialogType == STATEMENT)
			{
				var dialogData:DialogData = create(xml, STATEMENT);
				dialogData.entityID = entityID;

				if (dialogData.event == null)
				{
					dialogData.event = GameEvent.DEFAULT;
				}

				key = dialogData.event;
				
				if (dialogData.id != null)
				{
					key = dialogData.id;
				}
								
				data[key] = dialogData;
			}
			else if(dialogType == RANDOM_SET)
			{
				key = DataUtils.getString(xml.attribute("id"));
				dialogData = new DialogData();
				dialogData.id = key;
				
				if(key == null)
				{
					key = DataUtils.getString(xml.attribute("event"));
				}
				
				if(key == null)
				{
					key = GameEvent.DEFAULT;
				}
				
				dialogData.event = key;
				
				dialogData.dialogSet = getDialogDataListFromXML(xml);
				
				data[key] = dialogData
			}
		}
		
		private function getDialogDataListFromXML(xml:XML):Vector.<DialogData>
		{
			var list:Vector.<DialogData> = new Vector.<DialogData>();
			var dialogs:XMLList = xml.children();

			for (var n:uint = 0; n < dialogs.length(); n++)
			{
				list.push(create(dialogs[n], String(xml.name())));
			}
			
			return list;
		}
		
		private function findUniqueKey(dialogData:DialogData, data:Dictionary):void
		{
			if(data[GameEvent.DEFAULT] != null)
			{
				var duplicateKeyIndex:int = 0;
				
				while(data[GameEvent.DEFAULT + duplicateKeyIndex] != null)
				{
					duplicateKeyIndex++;
				}
				
				data[GameEvent.DEFAULT + duplicateKeyIndex] = data;
			}
		}
		
		private function parseConversation(xml:XML, data:Dictionary, entityID:String):void
		{
			var conversationData:XMLList = xml.children();
			var exchangeData:XMLList;
			var questions:XMLList;
			var currentDialog:XML;
			var exchange:Exchange;
			var conversation:Conversation = new Conversation();
			var key:String;

			conversation.questions = new Vector.<Exchange>();
			conversation.entityId = entityID;

			var id:String = DataUtils.getString(xml.attribute("id"));
			conversation.forceSpeaker = DataUtils.getBoolean(xml.attribute("forceSpeaker"));
			var event:String = DataUtils.getString(xml.attribute("event"));
			conversation.triggeredByEvent = DataUtils.getString(xml.attribute("triggeredByEvent"));

			if (event == null)
			{
				if(conversation.triggeredByEvent != null)
				{
					event = conversation.triggeredByEvent;
				}
				else
				{
					event = GameEvent.DEFAULT;
				}
			}

			conversation.id = id;
			conversation.event = event;

			if (id)
			{
				key = id;
			}
			else
			{
				key = event;
			}

			for (var i:uint = 0; i < conversationData.length(); i++)
			{
				exchangeData = XML(conversationData[i]).children();
				exchange = new Exchange();

				for (var n:uint = 0; n < exchangeData.length(); n++)
				{
					currentDialog = exchangeData[n];

					if (String(currentDialog.name()) == QUESTION)
					{
						exchange.question = create(currentDialog, QUESTION, id + QUESTION + i);
						exchange.question.entityID = entityID;
					}
					else if (String(currentDialog.name()) == ANSWER)
					{
						exchange.answer = create(currentDialog, ANSWER, id + ANSWER + i);
						exchange.answer.entityID = entityID;
					}
					else
					{
						trace("DialogParser :: Error, unknown exchange type.");
					}
				}

				conversation.questions.unshift(exchange);
			}

			data[key] = conversation;
		}

		private function create(xml:XML, type:String = null, id:String = null):DialogData
		{
			var dialogData:DialogData = new DialogData();
			var triggerEvent:DialogTriggerEvent;
			var triggerEventType:String = DataUtils.getString(xml.attribute("triggerEvent"));
			var customId:String = DataUtils.getString(xml.attribute("id"));

			if (type == null)
			{
				type = DataUtils.getString(xml.attribute("type"));
			}

			if (customId != null)
			{
				id = customId;
			}

			/*
			Drew Martin
			Temporary check to see if the dialog is actually an ID with "text#" to look up in LanguageManager's
			dictionaries. If it isn't, it's assumed to be the ACTUAL dialog the character is supposed to say.
			For now, this will fail if look up IDs don't contain "text#".
			*/
			var languageManager:LanguageManager = LanguageManager(this._group.shellApi.getManager(LanguageManager));
			var dialog:String = DataUtils.getString(xml.toString());
			if( DataUtils.validString(dialog) )
			{
				if(dialog.search(/text\d/) != -1)
				{
					if(dialog.indexOf(".") == -1)
					{
						dialog = "island." + this._scene + "." + dialog;
					}
					else
					{
						dialog = "island." + dialog;
					}

					var text:String = languageManager.get(dialog);
					if(text) dialog = text;
				}
			}

			dialogData.dialog = dialog;
			dialogData.id = id;
			dialogData.type = type;
			dialogData.link = DataUtils.getString(xml.attribute("link"));
			dialogData.triggeredByEvent = DataUtils.getString(xml.attribute("triggeredByEvent"));
			dialogData.linkEntityId = DataUtils.getString(xml.attribute("linkEntityId"));
			dialogData.timeOverride = DataUtils.useNumber(xml.attribute("timeOverride"), NaN);
			dialogData.forceOnScreen = DataUtils.getBoolean(xml.attribute("forceOnScreen"));
			dialogData.audioUrl = DataUtils.getString(xml.attribute("audioUrl"));

			if(DataUtils.getString(xml.attribute("style")) != "" && DataUtils.getString(xml.attribute("style")) != null)
				dialogData.style = DataUtils.getString(xml.attribute("style"));

			if (dialogData.audioUrl)
			{
				dialogData.audioUrl = _group.shellApi.preferredLanguage + "/" + dialogData.audioUrl;

				var gender:String = _group.shellApi.profileManager.active.gender;
				if ((gender == SkinUtils.GENDER_FEMALE) && (dialogData.audioUrl.toLowerCase().indexOf("playerma") != -1))
					dialogData.audioUrl = dialogData.audioUrl.replace("MA", "FA");

				if ((gender == SkinUtils.GENDER_MALE) && (dialogData.audioUrl.toLowerCase().indexOf("playerfa") != -1))
					dialogData.audioUrl = dialogData.audioUrl.replace("FA", "MA");
			}

			var event:String = DataUtils.getString(xml.attribute("event"));

			if (event == null)
			{
				if(dialogData.triggeredByEvent != null)
				{
					event = dialogData.triggeredByEvent;
				}
				else
				{
					event = GameEvent.DEFAULT;
				}
			}

			dialogData.event = event;

			if (triggerEventType != null)
			{
				triggerEvent = new DialogTriggerEvent();
				triggerEvent.event = triggerEventType;
				triggerEvent.args = DataUtils.getArray(xml.attribute("triggerEventArgs"));
				triggerEvent.triggerFirst = false;

				if(xml.attribute("triggerFirst"))
				{
					triggerEvent.triggerFirst = DataUtils.getBoolean(xml.attribute("triggerFirst"));
				}

				dialogData.triggerEvent = triggerEvent;
			}

			return(dialogData);
		}

		public static const CONVERSATION:String = "conversation";
		public static const QUESTION:String = "question";
		public static const ANSWER:String = "answer";
		public static const STATEMENT:String = "statement";
		public static const RANDOM_SET:String = "randomSet";
	}
}
