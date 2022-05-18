// Status: retired
// Usage (1) ads
// Used by avatar item ad_mh13wishes_lamp

package game.data.specialAbility.character
{	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.timeline.Timeline;
	import game.components.entity.character.Rig;
	import game.data.animation.entity.character.Sword;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.SceneUtil;

	public class MH13WishingLamp extends SpecialAbility
	{
		// On activate, player the stopped movieClip
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				SceneUtil.lockInput( super.group );
				
				CharUtils.stateDrivenOff( node.entity );

				super.setActive( true );
				CharUtils.setAnim( node.entity, Sword );
				CharUtils.getTimeline( node.entity ).handleLabel("hold", playStockClip);				
			}
		}
		
		// Play jinn animation
		private function playStockClip():void
		{
		//	CharUtils.getTimeline( node.entity ).paused = true;
			
			var rig:Rig =  super.entity.get( Rig );
			var item:Entity = rig.parts[ "item" ];
			
			var child:Children = item.get( Children );
			var lamp:Entity = child.children[0];
			
			var timeline:Timeline = lamp.get( Timeline );
			timeline.gotoAndPlay( 1 );
			timeline.handleLabel( "end", endStockClip);
			
			CharUtils.getTimeline( super.entity ).paused = true;
		}
		
		// Remove jinn animation and return control to player
		private function endStockClip():void
		{
			
			var rig:Rig =  node.entity.get( Rig );
			var item:Entity = rig.parts[ "item" ];
			
			var child:Children = item.get( Children );
			var lamp:Entity = child.children[0];
			
			var timeline:Timeline = lamp.get( Timeline );
			timeline.gotoAndStop( 0 );
			
			CharUtils.stateDrivenOn( super.entity );
			super.setActive();
			
			CharUtils.getTimeline( super.entity ).paused = false;
			SceneUtil.lockInput( super.group, false );
		}
	}
}