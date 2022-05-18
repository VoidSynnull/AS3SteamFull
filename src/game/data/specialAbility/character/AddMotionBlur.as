// Used by:
// Card "power_gem" on con1 island using overshirt poptropicon_hero2

package game.data.specialAbility.character
{
	import com.poptropica.AppConfig;
	
	import game.components.specialAbility.character.MotionBlur;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.specialAbility.character.MotionBlurSystem;

	/**
	 * Motion blur applied to avatar
	 * 
	 * Optional params:
	 * lifeTime 			Number		Blur lifetime (default is 1)
	 * blursPerSecond		Number		Number of blurs per second (default is 10)
	 * color				Number		Color of blur
	 * quality				Number		Quality of blur (default is 1)
	 */
	public class AddMotionBlur extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			//if mobile
			if(AppConfig.mobile)
			{
				_blursPerSecond *= .5;
				_lifeTime *= 2;
				_quality *= .5;
			}
			// create motion blur
			blur = new MotionBlur(_lifeTime, _blursPerSecond, _quality, _color);
			
			// add to avatar
			super.entity.add(blur);
			var motionBlurSystem:MotionBlurSystem = super.group.getSystem(MotionBlurSystem) as MotionBlurSystem;
			if(motionBlurSystem == null)
				super.group.addSystem(new MotionBlurSystem());
		}

		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.entity.remove(MotionBlur);
		}
		
		public var _lifeTime:Number = 1;
		public var _blursPerSecond:Number = 10;
		public var _color:Number = NaN;
		public var _quality:Number = 1;
		
		private var blur:MotionBlur;
	}
}
