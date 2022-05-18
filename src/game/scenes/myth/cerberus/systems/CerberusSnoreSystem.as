package game.scenes.myth.cerberus.systems
{
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.scenes.myth.cerberus.components.CerberusControlComponent;
	import game.scenes.myth.cerberus.components.CerberusSnoreComponent;
	import game.scenes.myth.cerberus.nodes.CerberusSnoreNode;
	import game.systems.GameSystem;
	
	public class CerberusSnoreSystem extends GameSystem
	{
		public function CerberusSnoreSystem( cerberusControl:CerberusControlComponent )
		{
			_cerberusControl = cerberusControl;
			super( CerberusSnoreNode, updateNode );
		}
		
		private function updateNode( node:CerberusSnoreNode, time:Number ):void
		{
			var spatial:Spatial;
			var display:Display;
			var snore:CerberusSnoreComponent;
			var tween:Tween;
			var randomX:Number;
			var randomY:Number;
			
			if( _cerberusControl.isSnoring )
			{
				spatial = node.spatial;	
				display = node.display;
				tween = node.tween;
				snore = node.snore;
				
				switch( snore.state )
				{
					case snore.DRIFT:
						break;
				
					case snore.START_DRIFT:	
						snore.counter ++;
						if( snore.counter > snore.waitTimer )
						{
							snore.counter = 0;
							spatial.rotation = Math.random() * 25 - 50;
							randomX = ( Math.random() * 3 * snore.headNumber ) - 25; 
							randomY = Math.random() * 10 + 120;
							
							if( snore.headNumber == 3 )
							{
								spatial.x -= 25;	
							}
							tween.to( display, 1.5, { alpha : 1, onComplete : alphaToZero, onCompleteParams : [ node ]});
							tween.to( spatial, 3, { x : spatial.x - randomX, y : spatial.y - randomY, onComplete : resetZee, onCompleteParams : [ node ]});
							snore.state = snore.DRIFT;
						}
						break;
				}
			}
		}
		
		private function alphaToZero( node:CerberusSnoreNode ):void
		{
			var display:Display = node.display;
			var tween:Tween = node.tween;
			
			tween.to( display, 1.5, { alpha : 0 });
		}
		
		private function resetZee( node:CerberusSnoreNode ):void
		{
			var spatial:Spatial = node.spatial;
			var snore:CerberusSnoreComponent = node.snore;
			
			spatial.x = snore.zeeStarterX;
			spatial.y = snore.zeeStarterY;
			spatial.rotation = 0;
			
			snore.state = snore.START_DRIFT;
		}
		
		private var _cerberusControl:CerberusControlComponent;
	}
}