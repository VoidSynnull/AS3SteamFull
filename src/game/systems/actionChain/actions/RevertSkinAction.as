package game.systems.actionChain.actions {

	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.entity.character.Skin;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionCommand;

	// Revert entity or entities to permanent skin settings 
	public class RevertSkinAction extends ActionCommand 
	{
		private var charType:String;

		/**
		 * Revert entity or entities to permanent skin settings 
		 * @param char		Entity to revert (can be a string constant "ALL" or "NPCS" or "FACING" to indicate an array of entities) 
		 */
		public function RevertSkinAction( char:* ) 
		{
			// if single entity, then store it
			if (char is Entity)
			{
				this.entity = char;
			}
			else if (char is String)
			{
				// else remember character type string
				charType = char;
			}
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
				var skin:Skin = char.get( Skin);
				if (skin)
					skin.revertAll();
			}
			callback();
		}
	}
}