package game.scenes.myth.shared.systems
{	
	import flash.display.Sprite;
	
	import engine.components.Display;
	
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.nodes.ElectrifyNode;
	import game.systems.GameSystem;
	
	public class ElectrifySystem extends GameSystem
	{
		private var numSparks:int = 10;
		
		public function ElectrifySystem(sparks:int=10)
		{
			super( ElectrifyNode, nodeUpdate );
			numSparks = sparks;
		}
		
		public function nodeUpdate( node:ElectrifyNode, time:Number ):void
		{
			var electrify:ElectrifyComponent = node.electrify;
			
			if( electrify.on )
			{
				var tempSprite:Vector.<Sprite> = new Vector.<Sprite>;
				var tempX:Vector.<Number> = new Vector.<Number>;
				var tempY:Vector.<Number> = new Vector.<Number>;
				var tempChild:Vector.<int> = new Vector.<int>;
				
				var number:int;
				
				var sprite:Sprite;
				var nextX:Number;
				var nextY:Number;
				var childNum:int;
				
				var display:Display = node.display;
				if( electrify.shockDisplay )
				{
					display = electrify.shockDisplay;
				}
				for( number = 0; number < numSparks; number ++ )
				{
					sprite = electrify.sparks.pop();
					nextX = electrify.lastX.pop();
					nextY = electrify.lastY.pop();
					childNum = electrify.childNum.pop();
					
					nextX += Math.random() * 24 - 12;
					nextY += Math.random() * 24 - 12;
					
					sprite.graphics.lineTo( nextX, nextY );
					sprite.alpha -= ( Math.random() * 2 ) / 10;
					
					if( sprite.alpha <= 0 )
					{
						sprite = new Sprite();
						sprite.name = "spark"+childNum;
						sprite.alpha = 1;
						nextX = ( Math.random() * display.displayObject.width ) - ( .5 * display.displayObject.width );
						nextY = ( Math.random() * display.displayObject.height ) - ( .5 * display.displayObject.height );
						
						sprite.graphics.lineStyle( 1, 0xFFFFFF );
						sprite.graphics.moveTo( nextX, nextY );
						
						display.displayObject.removeChildAt( childNum );
						display.displayObject.addChildAt( sprite, childNum );
					}
					
					tempSprite.push( sprite );
					tempX.push( nextX );
					tempY.push( nextY );
					tempChild.push( childNum );
				}
				
				for( number = 0; number < numSparks; number ++ )
				{
					electrify.sparks.push( tempSprite.pop() );
					electrify.lastX.push( tempX.pop() );
					electrify.lastY.push( tempY.pop() );
					electrify.childNum.push( tempChild.pop() );
				}
			}
		}
	}
}