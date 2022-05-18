package game.scenes.ghd.shared.mushroom
{
	import game.components.hit.Bounce;
	import game.components.hit.Wall;
	import game.systems.GameSystem;
	
	public class MushroomSystem extends GameSystem
	{
		private const TRIGGER:String	=	"trigger";
		
		public function MushroomSystem()
		{
			super( MushroomNode, updateNode, nodeAdded );
		}
		
		private function updateNode( node:MushroomNode, time:Number ):void
		{
			if( node.mushroom._invalidate && !node.mushroom._moving )
			{
				node.mushroom._moving = true;
				node.mushroom._invalidate = false;
				
				this.switchDirection( node );
			}
		}
		
		// TOGGLE THE LEFT/RIGHT BOUNCE PLATFORMS/WALLS DEPENDING ON DIRECTION
		private function switchDirection( node:MushroomNode ):void
		{
			if( node.mushroom.bounceLeft )
			{
				if( node.mushroom._facingLeft )
				{
					if( node.mushroom.bounceLeftDelta )
					{
						node.mushroom.bounceLeft.add( node.mushroom.bounceLeftDelta );
					}
					else if( node.mushroom.wallLeftDelta )
					{
						node.mushroom.bounceLeft.add( node.mushroom.wallLeftDelta );
					}
				}
				else
				{
					if( node.mushroom.bounceLeftDelta )
					{ 
						node.mushroom.bounceLeft.remove( Bounce );
					}
					else if( node.mushroom.wallLeftDelta )
					{
						node.mushroom.bounceLeft.remove( Wall );
					}
				}
			}
			if( node.mushroom.bounceRight )
			{
				if( node.mushroom._facingLeft )
				{
					if( node.mushroom.bounceRightDelta )
					{ 
						node.mushroom.bounceRight.remove( Bounce );
					}
					else if( node.mushroom.wallRightDelta )
					{
						node.mushroom.bounceRight.remove( Wall );
					}
				}
				else
				{
					if( node.mushroom.bounceRightDelta )
					{ 
						node.mushroom.bounceRight.add( node.mushroom.bounceRightDelta );
					}
					else if( node.mushroom.wallRightDelta )
					{
						node.mushroom.bounceRight.add( node.mushroom.wallRightDelta );
					}
				}
			}
			
			runTimeline( node );
		}
		
		// RUN THE BASE'S TIMELINE ONLY IF IT IS NOT THE SETUP PASS
		private function runTimeline( node:MushroomNode ):void
		{
			if( !node.mushroom._invalidate )
			{
				node.mushroom.stemTimeline.play();
				node.timeline.play();
				node.audio.playCurrentAction( TRIGGER );
			}
			
			else
			{
				if( node.mushroom._facingLeft )
				{
					node.timeline.gotoAndStop( "left" );
					if( node.mushroom.stemTimeline )
					{
						node.mushroom.stemTimeline.gotoAndStop( "left" );
					}
				}
				else
				{
					node.timeline.stop();
					if( node.mushroom.stemTimeline )
					{
						node.mushroom.stemTimeline.stop();
					}
				}
				
				node.mushroom._invalidate = false;
			}
		}
		
		// SET THEM TO THE CORRECT ORIENTATION
		private function nodeAdded( node:MushroomNode ):void
		{
			this.switchDirection( node );
		}
	}
}