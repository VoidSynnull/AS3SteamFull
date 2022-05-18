// Usage (1) ads
// Used by card 3512

package game.data.specialAbility.character
{		
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	
	import game.components.entity.character.Character;
	import game.creators.entity.character.CharacterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	
	public class TintAllCharacters extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			// if not currently active and no popup present
			if (!super.data.isActive)
			{
				// make active
				super.setActive(true);
				
				var randomIndex:int;
				
				// convert colors to array
				var tintColors:Array = _tintColors.split(",");
				var numberOfColors:int = tintColors.length;
				for (var i:int = 0; i != numberOfColors; i++)
				{
					tintColors[i] = Number(tintColors[i]);
				}
				
				if (_includePlayer)
				{
					randomIndex = Math.floor(Math.random() * numberOfColors);
					//ColorUtil.tint(node.entity.get(Display).displayObject, tintColors[randomIndex], _tintIntensity);
					tintCharacter(node.entity, tintColors[randomIndex], _tintIntensity);
				}
				
				var nodeList:NodeList = group.systemManager.getNodeList( NpcNode );
				for( var nodenpc : NpcNode = nodeList.head; nodenpc; nodenpc = nodenpc.next )
				{
					var npcEntity:Entity = nodenpc.entity;
					
					// skip mannequins
					if ((npcEntity.has(Character)) && (npcEntity.get(Character).variant == CharacterCreator.VARIANT_MANNEQUIN))
						continue;

					randomIndex = Math.floor(Math.random() * numberOfColors);
					// don't tint npc friends or followers
					var id:String = npcEntity.get(Id).id;
					if ((id.substring(0,10) != "npc_friend") && (id.indexOf("popFollower") != 0))
					{
						//ColorUtil.tint(nodenpc.display.displayObject, tintColors[randomIndex], _tintIntensity);
						tintCharacter(npcEntity, tintColors[randomIndex], _tintIntensity);
					}
				}
			}
		}
		
		static public function tintCharacter(npc:Entity, color:Number, intensity:int, includeEyes:Boolean = false):void
		{
			// all parts except for mouth, eyes, hands, feet
			var partList:Array = [CharUtils.SHIRT_PART,
				CharUtils.PANTS_PART,
				CharUtils.FACIAL_PART,
				CharUtils.MARKS_PART,
				CharUtils.PACK,
				CharUtils.HAIR,
				CharUtils.ITEM,
				CharUtils.OVERPANTS_PART,
				CharUtils.OVERSHIRT_PART,
				CharUtils.HAND_FRONT,
				CharUtils.HAND_BACK,
				CharUtils.ARM_FRONT,
				CharUtils.ARM_BACK,
				CharUtils.ARM_FRONT,
				CharUtils.LEG_BACK,
				CharUtils.LEG_FRONT,
				CharUtils.FOOT_FRONT,
				CharUtils.FOOT_BACK,
				CharUtils.BODY_PART,
				CharUtils.HEAD_PART];
			
			if (includeEyes)
			{
				partList.push(CharUtils.EYES_PART);
			}
			
			for each (var part:String in partList)
			{
				var partEntity:Entity = CharUtils.getPart(npc, part);
				if ((partEntity) && (partEntity.has(Display)))
				{
					var clip:DisplayObject = partEntity.get(Display).displayObject;
					ColorUtil.tint(DisplayObjectContainer(clip), color, intensity);
				}
			}
		}

		public var _tintColors:String = "0x000000";
		public var _tintIntensity:Number = 10; // percentage 0-100 of tint
		public var _includePlayer:Boolean = false;
	}
}