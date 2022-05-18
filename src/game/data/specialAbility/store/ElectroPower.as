// Used by:
// Card 3022 using ability electro_power

package game.data.specialAbility.store
{
	import flash.filters.GlowFilter;
	
	import game.components.render.DisplayFilter;
	import game.components.specialAbility.Sparks;
	import game.data.specialAbility.character.TintAllCharacters;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.render.DisplayFilterSystem;
	import game.systems.specialAbility.character.SparksSystem;
	import game.util.PlatformUtils;

	/**
	 * Electrify avatar with glow and electro balls
	 * 
	 * Optional params:
	 * offsetX 		Number		X offset (default is 0)
	 * offsetY		Number		Y offset (default is 0)
	 * color		Number		Color of effect (default is 0)
	 */
	public class ElectroPower extends SpecialAbility
	{
		public var _color:uint = 0;
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				node.entity.group.addSystem(new SparksSystem());
				node.entity.group.addSystem(new DisplayFilterSystem());
				
				this.data.isActive = true;
				
				var sparks:Sparks = new Sparks();
				sparks.bounds.setTo(-60, -200, 120, 350);
				node.entity.add(sparks);
				
				if (!PlatformUtils.isMobileOS)
				{
					var filter:DisplayFilter = new DisplayFilter();
					filter.filters.push(new GlowFilter(_color, 1, 100, 100, 1, 1, true));
					filter.filters.push(new GlowFilter(_color, 1, 20, 20, 1, 1));
					filter.filters.push(new GlowFilter(_color, 1, 8, 8, 1, 1, true));
					filter.inflate.setTo(20, 20);
					node.entity.add(filter);
				}
				else
				{
					TintAllCharacters.tintCharacter(node.entity, _color, 50, true);
				}
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			// turn off tint if mobile
			if (PlatformUtils.isMobileOS)
			{
				TintAllCharacters.tintCharacter(node.entity, 0xFFFFFF, 0, true);
			}
			node.entity.remove(Sparks);
			node.entity.remove(DisplayFilter);
		}
		/*
		private function addElectroBalls():void
		{
			if(electroEntity == null)
			{
				var clip : MovieClip = new MovieClip();
				super.entity.get(Display).container.addChild(clip);
				// Create the new entity and set the display and spatial
				electroEntity = new Entity();
				electroEntity.add(new Display(clip, super.entity.get(Display).container));
				
				var playerSpatial:Spatial = super.entity.get(Spatial);
				playerSpatial.y += _offsetY;
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = playerSpatial;
				followTarget.rate = 1;
				electroEntity.add(followTarget);
				
				if ( !super.group.getSystem( FollowTargetSystem ) )
				{
					super.group.addSystem(new FollowTargetSystem(), SystemPriorities.move);
				}
				electroEntity.add(new Spatial(playerSpatial.x+_offsetX, playerSpatial.y-50));
				electroEntity.get(Display).alpha = 0.65;
				for(var u : uint = 0; u < 3; u++)
				{
					aBalls[u] = new ElectricBall(0, new Point(0,0), "normal");
					clip.addChild(aBalls[u]);
				}
			}
			super.group.addEntity(electroEntity);
			for(var v : uint = 0; v < 3; v++)
			{
				newElectroPath(v);
			}
		}
		
		private function newElectroPath(u:uint):void{
			var sPartName : String = aPartNames[Math.floor(aPartNames.length * Math.random())];
			aBalls[u].x = 30 - Math.random() * 60;
			aBalls[u].y = 60 - Math.random() * 120 - 10;
			aBalls[u].scaleX = aBalls[u].scaleY = minScale + (maxScale - minScale) * Math.random();
			sPartName = aPartNames[Math.floor(aPartNames.length * Math.random())];
			var ballEndX : Number = 30 - Math.random() * 60;
			var ballEndY : Number = 60 - Math.random() * 120 - 10;
			var ballEndScale : Number = minScale + Math.random() * (maxScale - minScale);
			var nTweenTime : Number = 0.5 + Math.random() * 3;
			TweenMax.to(aBalls[u], nTweenTime, {x:ballEndX, y:ballEndY, scaleX:ballEndScale, scaleY:ballEndScale, onComplete:newElectroPath, onCompleteParams:[u]});
		}
		
		public var _offsetX:Number = 0;
		public var _offsetY:Number = 0;
		
		
		private var electroEntity : Entity;
		private var maxScale : Number = 0.4;
		private var minScale : Number = 0.05;
		private var aPartNames : Array = ["bodySkin", "pants", "shirt", "overpants", "foot1", "foot2", "marks", "eyes", "hand1", "hand2"];
		private var aBalls:Array=new Array();*/
	}

}