import pygame
import sys
import random

# Game settings
screen_width = 1000
screen_height = screen_width  # Flappiness!

background_color = (50, 150, 250)  # Light blue
hspeed = 5  # Speed of the bird
obstacle_interval = 1700
score_size = 122
gap_size = 400

class Bird(pygame.sprite.Sprite):
    def __init__(self):
        super().__init__()
        self.image = pygame.Surface((100, 100))  # Bird shape
        self.image.fill((255, 255, 255))  # Change bird color to white
        self.rect = self.image.get_rect(center=(screen_width // 2, screen_height // 2))  # Center bird
        self.velocity = -10  # Initial velocity

    def move_upwards(self):
        self.velocity = -10  # Adjust this value to control the movement speed

    def update(self):
        self.velocity += 0.4  # Simulate gravity
        self.rect.y += self.velocity  # Update position based on velocity
        
        # Prevent the bird from going off-screen
        if self.rect.top <= -100:
            self.rect.top = -100
        elif self.rect.bottom >= screen_height:
            self.rect.bottom = screen_height
            self.velocity = -self.velocity * 0.75  # Reset velocity when hitting the ground

class Obstacle(pygame.sprite.Sprite):
    def __init__(self, x, gap_size, height_range=(50, 450), width=100):
        super().__init__()
        self.gap_size = gap_size
        self.top_height = random.randint(*height_range)
        self.bottom_height = screen_height - self.top_height - gap_size
        self.scored = False
        
        # Create the top rectangle
        self.top_image = pygame.Surface((width, self.top_height))
        self.top_image.fill((255, 255, 255))
        self.top_rect = self.top_image.get_rect(topleft=(x, 0))
        
        # Create the bottom rectangle
        self.bottom_image = pygame.Surface((width, self.bottom_height))
        self.bottom_image.fill((255, 255, 255))
        self.bottom_rect = self.bottom_image.get_rect(topleft=(x, screen_height - self.bottom_height))
        
    def update(self):
        self.top_rect.x -= hspeed  # Move left
        self.bottom_rect.x -= hspeed  # Move left
        
        # Check if the obstacle is completely off the screen
        if self.top_rect.right < 0:
            self.kill()  # Remove this obstacle from any sprite groups
    
    def draw(self, screen):
        screen.blit(self.top_image, self.top_rect)
        screen.blit(self.bottom_image, self.bottom_rect)

def game_over_screen(screen):
    font = pygame.font.Font(None, 74)
    text = font.render("Game Over", True, (255, 0, 0))
    screen.blit(text, (screen_width // 2 - text.get_width() // 2, screen_height // 2 - text.get_height() // 2))
    pygame.display.flip()
    pygame.time.wait(2000)  # Display the game over text for 2 seconds

def main():
    pygame.init()
    screen = pygame.display.set_mode((screen_width, screen_height))
    pygame.display.set_caption("FlappyMax")

    bird_group = pygame.sprite.GroupSingle()
    bird = Bird()
    bird_group.add(bird)

    obstacles = pygame.sprite.Group()
    obstacle_timer = pygame.USEREVENT + 1
    pygame.time.set_timer(obstacle_timer, obstacle_interval)  # Adjust the timing as needed

    running = True
    clock = pygame.time.Clock()
    score = 0
    font = pygame.font.Font(None, score_size)

    while running:
        clock.tick(60)
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_SPACE:
                    bird.move_upwards()
            elif event.type == obstacle_timer:
                obstacles.add(Obstacle(screen_width, gap_size))

        collision = False
        for obstacle in obstacles:
            obstacle.update()
            if obstacle.top_rect.right < bird.rect.left and not obstacle.scored:
                score += 1
                obstacle.scored = True

            if bird.rect.colliderect(obstacle.top_rect) or bird.rect.colliderect(obstacle.bottom_rect):
                collision = True
                break

        if collision:
            game_over_screen(screen)
            bird_group.empty()
            obstacles.empty()

            # Reset the obstacle generation timer
            pygame.time.set_timer(obstacle_timer, 0)  # Stop the timer
            pygame.time.set_timer(obstacle_timer, obstacle_interval)  # Restart the timer with the original interval

            bird = Bird()
            bird_group.add(bird)
            score = 0  # Reset score
                
        screen.fill(background_color)
        for obstacle in obstacles:
            obstacle.draw(screen)
        
        bird_group.update()
        bird_group.draw(screen)
        
        # Display the score
        score_text = font.render(str(score), True, (255, 255, 255))
        screen.blit(score_text, (screen_width // 2 - score_text.get_width() // 2, 20))
        
        pygame.display.flip()

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
 
