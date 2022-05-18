package game.data.specialAbility.store
{
	import com.greensock.easing.Quad;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.render.FollowDisplayIndex;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.Grief;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.characterAnimations.Sweat;
	import game.scene.template.CharacterGroup;
	import game.systems.render.FollowDisplayIndexSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayAlignment;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class HeatWave extends SpecialAbility
	{
		private var heatWave:Entity;
		
		public function HeatWave()
		{
			super();
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			node.entity.group.addSystem(new FollowDisplayIndexSystem());
			
			this.setActive(true);
			this.shellApi.loadFile(this.shellApi.assetPrefix + "specialAbility/objects/heatWave.swf", heatWaveLoaded);
			
			var nodeList:NodeList = this.systemManager.getNodeList(NpcNode);
			var entityArray:Vector.<Entity> = CharacterGroup(node.entity.group.getGroupById("characterGroup")).getNPCs("NPCS");
			for each (var char:Entity in entityArray)
			{
				setSweat(char, true);
			}
			setSweat(node.entity, true);
			
		}
		
		private function setSweat(entity:Entity, add:Boolean = true):void
		{
			var sweat:Entity = EntityUtils.getChildById(entity, "heatWaveSweat");
			
			if(add)
			{
				if(!sweat)
				{
					CharUtils.setAnim(entity, Grief);
					var display:Display = entity.get(Display);
					
					var emitter:Emitter2D = new Emitter2D();
					
					emitter.counter = new Random( 10, 20 );
					
					emitter.addInitializer( new ImageClass( Dot, [2], true ) );
					emitter.addInitializer( new Position( new EllipseZone( new Point( -15, -15 ), 50, 5)));
					emitter.addInitializer( new Velocity( new LineZone( new Point( -60, -80 ), new Point( 60, -140 ) ) ) );
					emitter.addInitializer( new Lifetime( 1.2, 1.5 ) );
					
					emitter.addAction( new Age(Quadratic.easeIn) );
					emitter.addAction( new RandomDrift( 10, 0 ) );
					emitter.addAction( new Accelerate(0,200) );
					emitter.addAction( new Fade( .5, 0 ) );
					emitter.addAction( new Move() );
					
					sweat = EmitterCreator.create(this, display.displayObject.parent, emitter, 10, -15, entity, null, entity.get(Spatial), true, true);
					
					sweat.add(new FollowDisplayIndex(display.displayObject, 1));
					sweat.add(new Id("heatWaveSweat"));
				}
			}
			else
			{
				if(sweat)
				{
					sweat.group.removeEntity(sweat);
				}
			}
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			this.setActive(false);
			
			var nodeList:NodeList = this.systemManager.getNodeList(NpcNode);
			for(var npcNode:NpcNode = nodeList.head; npcNode; npcNode = npcNode.next)
			{
				setSweat(npcNode.entity, false);
			}
			setSweat(node.entity, false);
			
			if(heatWave && heatWave.group)
			{
				heatWave.group.removeEntity(heatWave);
			}
		}
		
		private function heatWaveLoaded(clip:MovieClip):void
		{
			if(this.data.isActive)
			{
				if(clip)
				{
					var bitmap:Bitmap = BitmapUtils.createBitmap(clip);
					bitmap.alpha = 0;
					this.shellApi.currentScene.overlayContainer.addChildAt(bitmap, 0);
					DisplayAlignment.stretchAndAlign(bitmap, new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight));
					heatWave = EntityUtils.createSpatialEntity(this.group, bitmap);
					
					var display:Display = heatWave.get(Display);
					display.alpha = 0.2;
					
					var tween:Tween = new Tween();
					tween.to(heatWave.get(Display), 1.5, {alpha:1, ease:Quad.easeOut, repeat:-1, yoyo:true});
					heatWave.add(tween);
				}
			}
		}
	}
}