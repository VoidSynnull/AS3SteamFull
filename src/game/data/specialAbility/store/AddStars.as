// Used by:
// Cards 3050, 3093, 3094, 3191 using ability stars_circle

package game.data.specialAbility.store
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.BevelFilter;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.SystemPriorities;

	/**
	 * Stars orbit avatar in a circle
	 * 
	 * optional params:
	 * xOffset 		Number		X offset (default is 0)
	 * yOffset 		Number		Y offset (default is 0)
	 */
	public class AddStars extends SpecialAbility
	{				
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.group.removeEntity(starsEntity);
			clip.removeEventListener(Event.ENTER_FRAME, updateStars);
		}
		
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				addStars();
			}
		}
		
		/**
		 * Add stars to avatar 
		 */
		private function addStars():void
		{
			if(starsEntity == null)
			{
				super.entity.get(Display).container.addChild(clip);
				var holderMC : MovieClip = new MovieClip();
				holderMC.y = -18;
				clip.addChild(holderMC);
				starsEntity = new Entity();
				starsEntity.add(new Display(clip, super.entity.get(Display).container));
				
				var playerSpatial:Spatial = super.entity.get(Spatial);
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = playerSpatial;
				followTarget.rate = 1;
				starsEntity.add(followTarget);
				
				if ( !super.group.getSystem( FollowTargetSystem ) )
				{
					super.group.addSystem(new FollowTargetSystem(), SystemPriorities.move);
				}
				starsEntity.add(new Spatial(playerSpatial.x+_xOffset, playerSpatial.y+_yOffset));
				
				var angleIncrement:Number = Math.PI / 5;  //5 pointed star -> 10 point arround the circle (360 degrees or Math.PI * 2): 5 outer points, 5 inner points
				var ninety:Number = Math.PI * .5;  //offset the rotation by 90 degrees so the star points up
				var starRadius:Number = 12;
				var numStars : Number = 10;
				for(var u : uint = 0; u < numStars; u++){
					aStars[u] = new MovieClip();
					var sSprite : Sprite = new Sprite();
					sSprite.graphics.lineStyle(1,0x000000);
					sSprite.graphics.moveTo(starRadius,0);
					sSprite.graphics.beginFill(0xFFFFFF);
					for(var i:int = 0; i <= 10; i++){//for each point
						var radius:Number = (i % 2 > 0 ? starRadius : starRadius * .5);//determine if the point is inner (half radius) or outer(full radius)
						var px:Number = Math.cos(ninety + angleIncrement * i) * radius;//compute x
						var py:Number = Math.sin(ninety + angleIncrement * i) * radius;//and y using polar to cartesian coordinate conversion
						if(i == 0) sSprite.graphics.moveTo(px,py);//move the 'pen' so we don't draw lines from (0,0)
						sSprite.graphics.lineTo(px,py);//draw each point of the star
					}
					sSprite.graphics.endFill();
					aStars[u].addChild(sSprite);
					aStars[u].orbitRadius = 75;
					aStars[u].angle = 2*Math.PI * (u / numStars);
					aStars[u].angleSpeed = 0.05;
					aStars[u].x = aStars[u].orbitRadius * Math.cos(aStars[u].angle);
					aStars[u].y = aStars[u].orbitRadius * Math.sin(aStars[u].angle);
					holderMC.addChild(aStars[u]);
				}
				var bF : BevelFilter = new BevelFilter(3, 45, 0xFFFFFF);
				clip.filters = [bF];
				clip.alpha = 0.7;
				clip.y = -45;
			}
			super.group.addEntity(starsEntity);
			clip.addEventListener(Event.ENTER_FRAME, updateStars);
		}
		
		/**
		 * Update stars on enterFrame (should use update instead) 
		 * @param e
		 */
		private function updateStars(e:Event):void{
			for(var u : uint = 0; u < aStars.length; u++){
				var starMC : MovieClip = aStars[u];
				starMC.angle += starMC.angleSpeed;
				starMC.x = starMC.orbitRadius * Math.cos(starMC.angle);
				starMC.y = starMC.orbitRadius * Math.sin(starMC.angle);
			}
		}
		
		public var _xOffset:Number = 0;
		public var _yOffset:Number = 0;
		
		private var clip:MovieClip = new MovieClip();
		private var starsEntity:Entity;
		private var aStars:Array=new Array();
	}
}