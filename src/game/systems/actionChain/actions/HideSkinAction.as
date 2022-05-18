package game.systems.actionChain.actions {

	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionCommand;
	import game.util.SkinUtils;

	// Hide skin part of entity or entities 
	// Can be used for any NPC, the player's avatar, all NPCs ("NPCS") or all ("ALL") or facing ("FACING") characters
	public class HideSkinAction extends ActionCommand 
	{
		private var charType:String;
		private var partType:String;
		private var revert:Boolean = false;

		/**
		 * Hide skin part of entity or entities
		 * @param char			Entity (can be a string constant "ALL" or "NPCS" or "FACING" to indicate an array of entities) 
		 * @param partType		Name of part type
		 * @param revert		Revert toggle (default is false)
		 */
		public function HideSkinAction( char:*, partType:String, revert:Boolean = false ) 
		{
			// if single entity, then add to array
			if (char is Entity)
			{
				this.entity = char;
			}
			else if (char is String)
			{
				// else remember character type ALL or NPCS
				charType = char;
			}
			
			this.partType = partType;
			this.revert = revert;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			var entityArray:Vector.<Entity>;
			
			// if NPCs or ALL
			if (charType)
			{
				entityArray = CharacterGroup(group.getGroupById("characterGroup")).getNPCs(charType);
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
			for each (var char:Entity in entityArray)
			{
				if ((revert) && (SkinUtils.isPartHidden(char, partType)))
					SkinUtils.hideSkinParts(char, new Array(partType), false);
				else
					SkinUtils.hideSkinParts(char, new Array(partType));
			}
			callback();
		}
	}
}