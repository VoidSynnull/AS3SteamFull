package game.util
{
	import com.greensock.TweenMax;
	
	import ash.core.Entity;
	
	import engine.components.Tween;
	import engine.group.Group;
	
	/**
	 * @author Scott Wszalek
	 * 
	 * Making it simpler to apply tweens to entites.
	 */
	public class TweenUtils
	{
		/**
		 * Creates a tween, adds it to the entity and adds the 'to' specified in the parameters.
		 * If the entity isn't going to persist throughout an entire scene and/or its Tween component
		 * is dependent on the Entity it's in, then use this function. Otherwise use the globalTo function.
		 * @param entityToTween - entity to add the tween to
		 * @param componentClass - the class of the component that we are tweening
		 * @param duration - how long the tween lasts
		 * @param vars - array with the paramters for the tween
		 * @param name - give the tween a name
		 * @param delay - if you want a delay before starting the tween - requires the group to not be null
		 */
		public static function entityTo(entityToTween:Entity, componentClass:Class, duration:Number, vars:Object, name:String = "", delay:Number = 0):TweenMax
		{
			var tween:Tween = entityToTween.get(Tween);
			var component:* = entityToTween.get(componentClass);
			
			if(!tween)
			{
				tween = new Tween();
				entityToTween.add(tween);
			}
			
			if(component == null)
			{
				trace("Error :: to : entity did not have component");
				return null;
			}
			
			var tweenMax:TweenMax = tween.to(component, duration, vars, name);
			tweenMax.delay = delay;
			return tweenMax;
		}

		/**
		 * Creates a tween, adds it to the entity and adds the 'from' specified in the parameters
		 * If the entity isn't going to persist throughout an entire scene and/or its Tween component
		 * is dependent on the Entity it's in, then use this function. Otherwise use the globalFrom function.
		 * @param entityToTween - entity to add the tween to
		 * @param componentClass - the class of the component that we are tweening
		 * @param duration - how long the tween lasts
		 * @param vars - array with the paramters for the tween
		 * @param name - give the tween a name
		 * @param delay - if you want a delay before starting the tween - requires the group to not be null
		 */
		public static function entityFrom(entityToTween:Entity, componentClass:Class, duration:Number, vars:Object, name:String = "", delay:Number = 0):TweenMax
		{
			var tween:Tween = entityToTween.get(Tween);
			var component:* = entityToTween.get(componentClass);
			
			if(!tween)
			{
				tween = new Tween();
				entityToTween.add(tween);
			}
			
			if(component == null)
			{
				trace("Error :: to : entity did not have component");
				return null;
			}
			
			var tweenMax:TweenMax = tween.from(component, duration, vars, name);
			tweenMax.delay = delay;
			return tweenMax;
		}
		
		/**
		 * Creates a tween, adds it to the entity and adds the 'fromTo' specified in the parameters.
		 * If the entity isn't going to persist throughout an entire scene and/or its Tween component
		 * is dependent on the Entity it's in, then use this function. Otherwise use the globalFromTo function.
		 * @param entityToTween - entity to add the tween to
		 * @param componentClass - the class of the component that we are tweening
		 * @param duration - how long the tween lasts
		 * @param vars - array with the paramters for the tween
		 * @param name - give the tween a name
		 * @param delay - if you want a delay before starting the tween - requires the group to not be null
		 * @param group - group that the entity is in
		 */
		public static function entityFromTo(entityToTween:Entity, componentClass:Class, duration:Number, fromVars:Object, toVars:Object, name:String = "", delay:Number = 0, group:Group = null):TweenMax
		{
			var tween:Tween = entityToTween.get(Tween);
			var component:* = entityToTween.get(componentClass);
			
			if(!tween)
			{
				tween = new Tween();
				entityToTween.add(tween);
			}
			
			if(component == null)
			{
				trace("Error :: to : entity did not have component");
				return null;
			}
			
			var tweenMax:TweenMax = tween.fromTo(component, duration, fromVars, toVars, name);
			tweenMax.delay = delay;
			return tweenMax;
		}
		
		/**
		 * Creates a to tween and adds it to the global entity.
		 * @param group - group that this tween will be in / current scene's group
		 * @param component - the component from the entity that we want to tween
		 * @param duration - length of the tween
		 * @param vars - array with the paramters for the tween
		 * @param name - the name to give the tween
		 * @param delay - if you want to delay the start of the tween, this is the length it will be delayed
		 */
		public static function globalTo(group:Group, component:*, duration:Number, vars:Object, name:String = "", delay:Number = 0):TweenMax
		{
			var groupTween:Tween = group.groupEntity.get(Tween);
			
			if(!groupTween)
			{
				groupTween = new Tween();
				group.groupEntity.add(groupTween);
			}
			
			if(component == null)
			{
				trace("Error :: to : entity did not have component");
				return null;
			}
				
			var tweenMax:TweenMax = groupTween.to(component, duration, vars, name);
			tweenMax.delay = delay;
			return tweenMax;
		}
		
		/**
		 * Creates a from tween and adds it to the global entity.
		 * @param group - group that this tween will be in / current scene's group
		 * @param component - the component from the entity that we want to tween
		 * @param duration - length of the tween
		 * @param vars - array with the paramters for the tween
		 * @param name - the name to give the tween
		 * @param delay - if you want to delay the start of the tween, this is the length it will be delayed
		 */
		public static function globalFrom(group:Group, component:*, duration:Number, vars:Object, name:String = "", delay:Number = 0):TweenMax
		{
			var groupTween:Tween = group.groupEntity.get(Tween);
			
			if(!groupTween)
			{
				groupTween = new Tween();
				group.groupEntity.add(groupTween);
			}
			
			if(component == null)
			{
				trace("Error :: to : entity did not have component");
				return null;
			}

			var tweenMax:TweenMax = groupTween.from(component, duration, vars, name);
			tweenMax.delay = delay;
			return tweenMax;
		}
		
		/**
		 * Creates a fromTo tween and adds it to the global entity.
		 * @param group - group that this tween will be in / current scene's group
		 * @param component - the component from the entity that we want to tween
		 * @param duration - length of the tween
		 * @param vars - array with the paramters for the tween
		 * @param name - the name to give the tween
		 * @param delay - if you want to delay the start of the tween, this is the length it will be delayed
		 */
		public static function globalFromTo(group:Group, component:*, duration:Number, fromVars:Object, toVars:Object, name:String = "", delay:Number = 0):TweenMax
		{
			var groupTween:Tween = group.groupEntity.get(Tween);
			
			if(!groupTween)
			{
				groupTween = new Tween();
				group.groupEntity.add(groupTween);
			}
			
			if(component == null)
			{
				trace("Error :: to : entity did not have component");
				return null;
			}

			var tweenMax:TweenMax = groupTween.fromTo(component, duration, fromVars, toVars, name);
			tweenMax.delay = delay;
			return tweenMax;
		}
	}
}