// Used by:
// Used in Sanctum scene in Arab2 using item oillamplit

package game.data.specialAbility.islands.arab 
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.util.Command;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.FlameCreator;
	import game.util.CharUtils;
	import game.util.EntityUtils;

	/**
	 * Add flames to item part
	 * 
	 * Optional params:
	 * _flameScale	Number	Scale value of flames (default is 0.6)
	 */
	public class AddDynamicFlames extends SpecialAbility
	{		
		override public function activate(node:SpecialAbilityNode):void
		{
			super.loadAsset("particles/fire_particle.swf", setupFire);
		}
		
		private function setupFire(clip:MovieClip):void
		{
			_flameCreator = new FlameCreator();
			MovieClip(Display(CharUtils.getPart(super.entity,CharUtils.ITEM).get(Display)).displayObject).addChild(clip);
			_flameCreator.setup( super.group, clip, null, Command.create(onFlameLoaded, clip) );
		}
		
		private function onFlameLoaded(clip:MovieClip):void
		{
			clip.x -= 155;
			clip.y -= 30;
			clip.scaleX = _flameScale;
			clip.scaleY = _flameScale;
			flame = _flameCreator.createFlame( super.group, clip, true );
			EntityUtils.addParentChild(flame, super.entity);
		}
		
		public var _flameScale:Number = 0.6;
		public var startingScale:Number = 0.6;
		
		private var flame:Entity;
		private var _flameCreator:FlameCreator;
	}
}