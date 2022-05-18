// Status: retired
// Usage (1) ads
// Used by card 2547

package game.data.specialAbility.character
{		
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.ColorUtil;
	
	public class TintAllCharacters extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			var randomIndex:int;
			
			var tintColors:Array = new Array();
			var tintIntensities:Array = new Array();
			
			var numberOfColors:int = 1;
			while ( super.data.params.byId( "tintColor" + numberOfColors) && super.data.params.byId( "tintIntensity" + numberOfColors) )
			{
				tintColors.push(uint( super.data.params.byId( "tintColor" + numberOfColors) ));
				tintIntensities.push(int( super.data.params.byId( "tintIntensity" + numberOfColors) ));
				numberOfColors ++;
			}
			numberOfColors --;
				
			if ( String( super.data.params.byId( "includePlayer" ) ).toLowerCase() == "true" )
			{
				randomIndex = randomInteger(0, numberOfColors - 1);
				ColorUtil.tint(node.entity.get(Display).displayObject, tintColors[randomIndex], tintIntensities[randomIndex]);
			}
				
				
			var nodeList:NodeList = super.group.systemManager.getNodeList( NpcNode );
			for( var nodenpc : NpcNode = nodeList.head; nodenpc; nodenpc = nodenpc.next )
			{
				randomIndex = randomInteger(0, numberOfColors - 1);
				// don't tint npc friends
				if (nodenpc.entity.get(Id).id.substring(0,10) != "npc_friend")
					ColorUtil.tint(nodenpc.display.displayObject, tintColors[randomIndex], tintIntensities[randomIndex]);
			}
			
			super.shellApi.specialAbilityManager.removeSpecialAbility(scene.shellApi.player, super.data.id);
		}
			
		private function randomInteger(lowNumber:Number, highNumber:Number):Number
		{
			return Math.floor(Math.random() * ( 1 + highNumber - lowNumber)) + lowNumber;
		}
	}
}

