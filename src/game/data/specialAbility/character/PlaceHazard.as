// Used by:
// Card 2693 using item limited_banana_peel (place banana peel hazard which avatar can slip on)

package game.data.specialAbility.character
{	
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	
	/**
	 * Place hazard object on ground
	 * 
	 * Optional params:
	 * knockBackVelocity	Array		Knock back velocity (default is 400,400)
	 * velocityByHitAngle	Boolean		Velocity by hit angle (default is true)
	 * slipThrough			Boolean		Slip through effect (default is false)
	 * hitAudioFile			String		Name of hit audio effect file when avatar collides with object
	 */
	public class PlaceHazard extends PlaceObject
	{
		/**
		 * Extra processing for hazard
		 * @param groundEntity
		 */
		override protected function additionalSetup(groundEntity:Entity):void
		{
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.showHits = true;
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackVelocity = new Point(_knockBackVelocity[0], _knockBackVelocity[1]);;
			hazardHitData.knockBackCoolDown = .75;
			hazardHitData.velocityByHitAngle = _velocityByHitAngle;
			hazardHitData.slipThrough = _slipThrough;
			var hazardHit:Entity = hitCreator.createHit(_clip, HitType.HAZARD, hazardHitData, super.group, true, true);
			if (_hitAudioFile)
				hitCreator.addAudioToHit(hazardHit, _hitAudioFile);
			// need this to get sound to work on base ground
			hitCreator.createHit(_clip, HitType.PLATFORM, null, super.group, true, true);
		}
		
		public var _knockBackVelocity:Array = new Array(400,400);
		public var _velocityByHitAngle:Boolean = true;
		public var _slipThrough:Boolean = false;
		public var _hitAudioFile:String;
	}
}