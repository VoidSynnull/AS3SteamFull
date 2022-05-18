package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.data.scene.characterDialog.Conversation;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.characterDialog.DialogParser;
	import game.data.scene.characterDialog.DialogTriggerEvent;
	import game.data.text.TextStyleData;
	import game.managers.TextManager;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.CharacterDialogSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.scene.SceneDialogSystem;
	import game.systems.ui.WordBalloonSystem;
	import game.ui.characterDialog.DialogTriggerDelegate;
	import game.ui.popup.Popup;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	public class CharacterDialogGroup extends Group implements DialogTriggerDelegate
	{
		public function CharacterDialogGroup()
		{
			super();
			super.id = GROUP_ID;
		}
		
		override public function destroy():void
		{
			shellApi.languageChanged.remove(updateLanguage);
			_dialogContainer = null;
			super.destroy();
		}
		
		/**
		 * Setup group to enable character driven dialog.
		 * NOTE :: Entities receiving dialog must already be created and given appropriate id.
		 * Parses xml into Dictionary of acceptable dialog formats (they vary) for each character.
		 */
		public function setupGroup(group:DisplayGroup, xml:XML, dialogContainer:DisplayObjectContainer):void
		{
			_dialogContainer = dialogContainer;
			// add it as a child group to give it access to systemManager.
			group.addChildGroup(this);
			
			// triggers conversations and statements 
			var characterDialogSystem:CharacterDialogSystem = new CharacterDialogSystem();
			characterDialogSystem.defaultDialogContainer = dialogContainer;
			characterDialogSystem.cameraLimits = (group is Scene) ? Scene(group).sceneData.cameraLimits : null;
			group.addSystem(characterDialogSystem, SystemPriorities.update);
			// hides dialog when the player starts moving 
			group.addSystem(new SceneDialogSystem(), SystemPriorities.update);
			// creates and destroys word balloon entities
			group.addSystem(new WordBalloonSystem(), SystemPriorities.update);
			// moves word balloons to their target entity
			group.addSystem(new FollowTargetSystem(), SystemPriorities.move);
			
			addAllDialog(xml);
			
			// handle events from word balloons
			var wordBalloonSystem:WordBalloonSystem = super.parent.getSystem(WordBalloonSystem) as WordBalloonSystem;
			wordBalloonSystem.dialogTriggerDelegate = this;
			
			shellApi.languageChanged.add(updateLanguage);
		}
		
		/**
		 * Assign all dialog to its character
		 */
		public function addAllDialog(dialogXml:XML, addToExisting:Boolean = false):void
		{
			var textManager:TextManager = TextManager(shellApi.getManager(TextManager));
			
			if (dialogXml != null)
			{
				var dialogParser:DialogParser = new DialogParser(this);
				var conversation:Conversation;
				var newDialogData:Dictionary = dialogParser.parse(dialogXml);

				if(newDialogData != null)
				{
					var entity:Entity;
					var id:String;
					
					for (id in newDialogData)
					{
						// add the textstyledata to the dialogdata so that we can use it later in WordBallonCreator
						for(var char:String in newDialogData[id])
						{
							// Must go into dialogs for each question and answer
							if(newDialogData[id][char] is Conversation)
							{
								conversation = newDialogData[id][char];
								for(var i:int = 0; i < conversation.questions.length; i++)
								{
									// question
									if(conversation.questions[i].question.style != null)
										conversation.questions[i].question.textStyleData = textManager.getStyleData(TextStyleData.DIALOG, conversation.questions[i].question.style);
									else
										conversation.questions[i].question.textStyleData = textManager.getStyleData(TextStyleData.DIALOG, "default");
									
									// answer
									if( conversation.questions[i].answer )
									{
										if(conversation.questions[i].answer.style != null)
											conversation.questions[i].answer.textStyleData = textManager.getStyleData(TextStyleData.DIALOG, conversation.questions[i].answer.style);
										else
											conversation.questions[i].answer.textStyleData = textManager.getStyleData(TextStyleData.DIALOG, "default");
									}
								}
							}
							else
							{
								// just a statement
								if(newDialogData[id][char].hasOwnProperty("style") && newDialogData[id][char].style != null)
									newDialogData[id][char].textStyleData = textManager.getStyleData(TextStyleData.DIALOG, newDialogData[id][char].style);
								else
									newDialogData[id][char].textStyleData = textManager.getStyleData(TextStyleData.DIALOG, "default");
							}
						}
						
						entity = super.parent.getEntityById(id);
						
						if(entity != null)
						{
							addDialog(entity, newDialogData[id]);
						}
						
						if(addToExisting)
						{
							if(this.allDialogData != null)
							{
								this.allDialogData[id] = newDialogData[id];
							}
						}
					}
					
					// if we didn't have a dictionary to start with, replace primary with new data.
					if(this.allDialogData == null)
					{
						this.allDialogData = newDialogData;
					}
				}
			}
		}
		
		
		private function updateLanguage(newDialogXML:XML):void {
			//trace("change language to", ['en','fr','es','pt'][newLanguage], 'get cached', shellApi.dataPrefix + groupPrefix + shellApi.localizedDialogFilename);
			addAllDialog(newDialogXML);
		}
		
		/**
		 * Assign dialog to character
		 */
		private function addDialog(entity:Entity, dialogData:Dictionary):void
		{
			var dialogComponent:Dialog = entity.get(Dialog);
			
			if(dialogComponent == null)
			{
				dialogComponent = new Dialog();
				entity.add(dialogComponent);
			}
			
			dialogComponent.allDialog = dialogData;
			
			super.shellApi.setupEventTrigger(dialogComponent);
		}
		
		/**
		 * Assign dialog to character
		 */
		public function assignDialog( entity:Entity, id:String = "" ):void
		{
			if( !DataUtils.validString(id) )
			{
				var idComponent:Id = entity.get(Id);
				if( idComponent )
				{
					id = idComponent.id;
				}
				else
				{
					id = entity.name;
				}
			}
			var dialogData:Dictionary = this.allDialogData[id];
			if( dialogData )
			{
				var dialog:Dialog = entity.get(Dialog);
				if(dialog == null)
				{
					dialog = new Dialog();
					entity.add(dialog);
				}
				dialog.allDialog = dialogData;
				super.shellApi.setupEventTrigger(dialog);
			}
		}
		
		/**
		 * Handles events triggered by dialog associated with word balloons.
		 * Implements DialogTriggerDelegate method
		 * @param dialogData
		 */
		public function handleDialogTriggerEvent(dialogData:DialogData):void
		{
			var triggerEvent:DialogTriggerEvent = dialogData.triggerEvent;
			var event:String = triggerEvent.event;
			var args:Array = triggerEvent.args;
			var giveID:String;
			var takeID:String;
			var charID:String;
			var removeItem:Boolean = true;
			var itemGroup:ItemGroup = super.getGroupById("itemGroup") as ItemGroup;
			
			var waitCompleteHandler:Function = ( triggerEvent.triggerFirst ) ? Command.create(startDialog, dialogData) : null;
			
			switch(event)
			{
				case DialogTriggerEvent.GIVE_ITEM :
					var i:int = 0;
					giveID = args[i];
					while(giveID != null)
					{
						if (!super.shellApi.checkItemEvent(giveID, true))
						{
							dialogData.waitingToStart = triggerEvent.triggerFirst;
							super.shellApi.getItem(giveID, null, true, waitCompleteHandler);
						}
						giveID = args[++i];
					}
					break;
				
				case DialogTriggerEvent.TAKE_ITEM :
					takeID = args[0];
					charID = args[1];
					if(args[2] != null) removeItem = args[2] == "true";
					
					if (super.shellApi.checkHasItem(takeID))
					{
						if(removeItem)
						{
							super.shellApi.removeItem(takeID);
						}
						
						if(itemGroup) 
						{ 
							dialogData.waitingToStart = triggerEvent.triggerFirst;
							itemGroup.takeItem(takeID, charID, "", null, waitCompleteHandler); 
						}
					}
					break;
				
				case DialogTriggerEvent.EXCHANGE_ITEMS :
					takeID = args[0];
					giveID = args[1];
					
					if (super.shellApi.checkHasItem(takeID))
					{
						super.shellApi.removeItem(takeID);
					}
					
					if (!super.shellApi.checkItemEvent(giveID))
					{
						dialogData.waitingToStart = triggerEvent.triggerFirst;
						super.shellApi.getItem(giveID, null, true, waitCompleteHandler);
					}
					
					//if(itemGroup) { itemGroup.showItem(giveID); }
					break;
				
				case DialogTriggerEvent.COMPLETE_EVENT :
					super.shellApi.completeEvent(args[0], args[1]);
					break;
				
				case DialogTriggerEvent.TRIGGER_EVENT :
					super.shellApi.triggerEvent(args[0], DataUtils.getBoolean(args[1]));
					
					if(args[1] == "true")
					{
						shellApi.track(args[0]);
					}
					
					break;
				
				case DialogTriggerEvent.OPEN_POPUP :
					var popupClass:Class = ClassUtils.getClassByName( args[0] );
					args.shift();
					dialogData.waitingToStart = triggerEvent.triggerFirst;
					var popup:Popup = new popupClass( super.shellApi.sceneManager.currentScene.overlayContainer, args ) as Popup;
					popup.popupRemoved.addOnce( waitCompleteHandler );
					super.shellApi.sceneManager.currentScene.addChildGroup( popup );
					break;
				
				case DialogTriggerEvent.APPLY_PART :
					var partId:String = String( args[0] );
					var partValue:String = String( args[1] );
					SkinUtils.getSkinPart( super.shellApi.player, partId ).setValue( partValue );
					break;
			}
		}
		
		private function startDialog(dialogData:DialogData, ...args):void
		{
			dialogData.waitingToStart = false;
		}
		
		public var allDialogData:Dictionary;
		private var _dialogContainer:DisplayObjectContainer;
		public static const GROUP_ID:String = "characterDialogGroup";
	}
}