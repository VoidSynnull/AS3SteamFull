// Used by:
// Card 3366 using marks survival_merithat (survival island)

package game.data.specialAbility.store
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.ui.card.EpisodicIslandData;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	/**
	 * Configure episodic island based on part params
	 * 
	 * Required params:
	 * type			String		Part type
	 * island		String		Island name
	 * episodes		Number		Number of episodes
	 */
	public class EpisodicIslandPart extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			var part:Entity = SkinUtils.getSkinPartEntity(node.entity, _type);
			var display:MovieClip = EntityUtils.getDisplayObject(part) as MovieClip;
			var isMale:Boolean = (super.shellApi.profileManager.active.gender == "male");
			var islandData:Vector.<EpisodicIslandData> = EpisodicIslandData.generateIslandData(super.shellApi, _island, _episodes);
			
			EpisodicIslandData.configureContent(display, islandData, isMale);
		}
		
		public var required:Array = ["type", "island", "episodes"];
		
		public var _type:String;
		public var _island:String;
		public var _episodes:Number;
	}
}