package game.systems.actionChain.actions
{
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.character.BitmapCharacter;
	import game.components.entity.character.part.SkinPart;
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionCommand;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.SkinUtils;
	
	// Set skin part of entity or entities 
	// Can be used for any NPC, the player's avatar, all NPCs ("NPCS") or all ("ALL") or facing ("FACING") or nearest ("NEAREST") characters
	public class SetLookAction extends ActionCommand 
	{
		private var lookString:String;
		private var look:LookData;
		private var permanent:Boolean;
		private var waitForLoad:Boolean;
		private var revert:Boolean = false;
		private var color:uint = 1;
		private var suffix:Number = 0;
		private var colorize:Boolean = true;
		private var searchTerm:String;
		
		private var _charType:String;
		private var _oldParts:Dictionary = new Dictionary();
		private var _callback:Function;
		private var _counter:int = 0;
		
		/**
		 * Set skin part of entity or entities 
		 * @param char			Entity whose skin to update (can be a string constant "ALL" or "NPCS" or "FACING" to indicate an array of entities) 
		 * @param partType		Name of part type
		 * @param partId		Name of part - can be comma delimited list (for random use) or in form: "M:part1,part2,part3|F:part1,part2,part3" (for random looks by gender)
		 * @param permanent		Make part permanent
		 * @param waitForLoad	Wait for part to load - if true, the action will not complete until the part is fully loaded and will check if there is a timeline to play
		 * @param revert		Revert to permanent if the part has already been applied (only works if the previous update was not permanent)
		 * @param color			Color value for part
		 */
		public function SetLookAction( char:*, lookString:String, permanent:Boolean=false, searchTerm:String=null) 
		{
			// if single entity, then store
			if (char is Entity)
			{
				this.entity = char;
			}
			else if (char is String)
			{
				// else remember character type string
				_charType = char;
			}
			
			this.lookString = lookString;
			this.permanent = permanent;
			this.searchTerm = searchTerm;

		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			_callback = callback;
			_counter = 0;
			
			var entityArray:Vector.<Entity>;
			
			// if NPCs or ALL or FACING or NEAREST
			if (_charType)
			{
				// don't allow on Poptropicon islands
				var currentIsland:String = group.shellApi.island;
				if ( (currentIsland == "con1") || (currentIsland == "con2") || (currentIsland == "con3") )
				{
					// show block dialog
					showBlockDialog(group);
					callback();
					return;
				}
				entityArray = CharacterGroup(group.getGroupById("characterGroup")).getNPCs(_charType);
				
				// if no entities then end action
				if (entityArray.length == 0)
				{
					callback();
					return;
				}
			}
			else if (entity)
			{
				// if entity then create vector with single entity
				entityArray = new <Entity>[entity];
			}
			else
			{
				// else fail gracefully
				callback();
				return;
			}
			
		
			// for each char
			for each(var char:Entity in entityArray)
			{
				// don't update blimp NPC
				if (char.get(Id).id == "custom_blimp_npc")
					continue;
				if(char.get(BitmapCharacter) != null)
					continue;
				
				// increment entity counter
				_counter++;
				
				var lookConverter:LookConverter = new LookConverter();
				// Including test look values against partKey to identify frames that need to be converted to labels
				
				
				if(lookString.indexOf("/") != -1)
				{
					var lookArray:Array = lookString.split("/");
					var pos:int = Math.floor(lookArray.length * Math.random());
					if(lookArray[pos] == "playerLook")
					{
						look = SkinUtils.getLook(node.owning.group.shellApi.player, true);
					}
					else
						look = lookConverter.lookDataFromLookString(lookArray[pos]);
					var newlookstr:String = lookArray[pos];
					var lookstr:String = lookConverter.getLookStringFromLookData(SkinUtils.getLook(node.owning.group.shellApi.player, false));
					if(searchTerm)
					{
						if(newlookstr.indexOf(searchTerm) != -1 && lookstr.indexOf(searchTerm) != -1 || newlookstr.indexOf(searchTerm) == -1 && lookstr.indexOf(searchTerm) == -1)
						{
							
							pos++;
							if(pos > lookArray.length-1)
								pos = 0;
							look = lookConverter.lookDataFromLookString(lookArray[pos]);
						}
						
					}
				}
				else
					look = lookConverter.lookDataFromLookString(lookString);
			
				SkinUtils.applyLook(char,look,permanent);
				completeAction();
				
			}
		}
		
		/**
		 * get random gender part from gender array and set array index for all future parts 
		 * @param char
		 * @param index
		 * @param arr
		 * @return String
		 */
		private function getRandomGenderPart(char:Entity, arr:Array):String
		{
			var index:int = -1;
			
			// get index if already applied, then get it
			if (char.get(Display).displayObject.arrayIndex != null)
				index = char.get(Display).displayObject.arrayIndex;
			
			// if no index yet, then create random one and apply to char
			if (index == -1)
			{
				index = Math.floor(arr.length * Math.random());
				char.get(Display).displayObject.arrayIndex = index;
			}
			// keep index within range
			if (index > arr.length - 1)
				index = arr.length - 1;
			return arr[index];
		}
		
		/**
		 * Show dialog saying that the action is blocked
		 * @param group
		 */
		private function showBlockDialog( group:Group ):void
		{
			var ID:String = "BlockAbility";
			if (group.getGroupById(ID) == null)
			{
				var dialogBox:ConfirmationDialogBox = new ConfirmationDialogBox(1, "This feature cannot be used on this island.");
				dialogBox.id = ID;
				dialogBox = ConfirmationDialogBox(group.addChildGroup(dialogBox));
				dialogBox.darkenBackground     = true;
				dialogBox.pauseParent         = false;
				dialogBox.init(Scene(group).overlayContainer);
			}
		}
		
	
		private function completeAction():void
		{
			// decrement for each entity
			_counter--;
			// only execute callback once (since there may be many completions at the same time)
			if (_counter == 0)
				_callback();
		}
	}
}


