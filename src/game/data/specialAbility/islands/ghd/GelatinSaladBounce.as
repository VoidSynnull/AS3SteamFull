// Used by
// Card "gelatin_salad" using item ghd_gelatin

package game.data.specialAbility.islands.ghd
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Bounce;
	import game.components.hit.CurrentHit;
	import game.components.hit.ValidHit;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Overhead;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.GameScene;
	import game.scenes.ghd.ghostShip.GhostShip;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	/**
	 * Carry bouncing jello over head 
	 */
	public class GelatinSaladBounce extends SpecialAbility
	{
		private var bounce:Entity;
		private var rigAnim:RigAnimation;
		private var charMotion:CharacterMotionControl;
		
		override public function init(node:SpecialAbilityNode):void
		{			
			super.init(node);
			
			charMotion = CharacterMotionControl( super.entity.get(CharacterMotionControl));
			// raise hands over head & add bounce
			//raiseJello();
		}
		
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if(shellApi.currentScene.id == "GhostShip")
			{
				Dialog(super.entity.get(Dialog)).say("I don't need this here");
				SkinUtils.emptySkinPart(super.entity,SkinUtils.ITEM);
			}
			else
			{
				super.data.isActive = true;
				if(!rigAnim){
					raiseJello();
				}
			}

		}
		
		private function raiseJello():void{
			var valid:ValidHit = super.entity.get(ValidHit);
			if(!valid){
				valid = new ValidHit();
				super.entity.add(valid);
			}
			valid.inverse = true;
			
			valid.setHitValidState("climb",false);
			valid.setHitValidState("jello",false);
			
			
			rigAnim = CharUtils.getRigAnim(super.entity, 1);
			if(rigAnim == null)
			{
				var animationSlot:Entity = AnimationSlotCreator.create(super.entity);
				rigAnim = animationSlot.get(RigAnimation) as RigAnimation;
			}
			rigAnim.next = Overhead;
			rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK);
			
			var gello:Entity = SkinUtils.getSkinPartEntity(super.entity, SkinUtils.ITEM);
			Spatial(gello.get(Spatial)).rotation=0;
			Timeline(gello.get(Timeline)).stop();
			
			SceneUtil.addTimedEvent(super.group, new TimedEvent(0.5, 1, addBounce));
		}
		
		private function addBounce():void
		{
			bounce = super.group.getEntityById("jello");
			if(bounce){
				bounce.get(Display).isStatic = false;
				bounce.get(Display).visible = false;
				bounce.add(new Sleep(false,true));
				var follow:FollowTarget = new FollowTarget(super.entity.get(Spatial));
				follow.offset = new Point(0, -super.entity.get(Spatial).height + 45);
				bounce.add(follow);
			}
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			super.data.isActive = false;
			if(node.entity.get(ValidHit))
			{
				node.entity.get(ValidHit).setHitValidState("climb",true);
				if(rigAnim){
					rigAnim.manualEnd = true;
					if(bounce){
						bounce.remove(FollowTarget);
						EntityUtils.position(bounce, -100, -100);
					}
				}
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			// check for meteor, bounce it in direction we're facing
			var meteor:Entity = super.group.getEntityById("meteor");
			if(meteor != null){
				var currHit:CurrentHit = meteor.get(CurrentHit);
				var hit:Entity = currHit.hit;
				if(hit && hit.has(Bounce)){
					var gel:Entity = SkinUtils.getSkinPartEntity(node.entity, SkinUtils.ITEM);
					Timeline(gel.get(Timeline)).gotoAndPlay("spring");
				}
			}	
			charMotion.spinEnd = true;
		}
	}
}