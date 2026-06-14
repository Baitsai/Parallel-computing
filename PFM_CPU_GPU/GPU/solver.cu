#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>

#define M_PI 3.14159265358979323846
#define GAMMA 1.4
#define R_GAS 1.0
#define CFL 1.0
#define Nf 300
#define FLUID 0
#define SOLID 1
#define SBL 0.6
#define SBH 0.2
#define threads 256

float *h_block_max; // 存GPU算出來每個block的最大速度
float *h_cx_pool, *h_cy_pool;
float *h_rho, *h_u, *h_v, *h_pres;
int *h_solid;

float *d_block_max;
float *d_cx_pool, *d_cy_pool;
float *d_pres, *d_u, *d_v, *d_temp, *d_rho, *d_rhou, *d_rhov, *d_E;
float *d_rho_new, *d_rhou_new, *d_rhov_new, *d_E_new;
int *d_solid;

void Allocate_Memory(int total_size, int blocks_ncell){
    h_block_max = (float *)malloc(blocks_ncell * sizeof(float));
    h_rho       = (float *)malloc(total_size * sizeof(float));
    h_u         = (float *)malloc(total_size * sizeof(float));
    h_v         = (float *)malloc(total_size * sizeof(float));
    h_pres      = (float *)malloc(total_size * sizeof(float));
    h_cx_pool   = (float *)malloc(Nf * sizeof(float));
    h_cy_pool   = (float *)malloc(Nf *sizeof(float));    
    h_solid     = (int *)malloc(total_size * sizeof(int));
    
    cudaError_t Error; 
    Error = cudaMalloc((void**)&d_cx_pool, Nf*sizeof(float));
    printf("CUDA error (d_cx_pool) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_cy_pool, Nf*sizeof(float));
    printf("CUDA error (d_cy_pool) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_pres, total_size*sizeof(float));
    printf("CUDA error (d_pres) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_u, total_size*sizeof(float));
    printf("CUDA error (d_u) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_v, total_size*sizeof(float));
    printf("CUDA error (d_v) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_temp, total_size*sizeof(float));
    printf("CUDA error (d_temp) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_rho, total_size*sizeof(float));
    printf("CUDA error (d_rho) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_rhou, total_size*sizeof(float));
    printf("CUDA error (d_rhou) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_rhov, total_size*sizeof(float));
    printf("CUDA error (d_rhov) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_E, total_size*sizeof(float));
    printf("CUDA error (d_E) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_rho_new, total_size*sizeof(float));
    printf("CUDA error (d_rho_new) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_rhou_new, total_size*sizeof(float));
    printf("CUDA error (d_rhou_new) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_rhov_new, total_size*sizeof(float));
    printf("CUDA error (d_rhov_new) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_E_new, total_size*sizeof(float));
    printf("CUDA error (d_E_new) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_solid, total_size*sizeof(int));
    printf("CUDA error (d_solid) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)&d_block_max, blocks_ncell*sizeof(float));
    printf("CUDA error (d_block_max) = %s\n", cudaGetErrorString(Error));
}

void Free_Memory(){
    free(h_block_max);
    free(h_cx_pool);
    free(h_cy_pool);
    free(h_rho);
    free(h_u);
    free(h_v);
    free(h_pres);
    free(h_solid);
    cudaFree(d_block_max);
    cudaFree(d_cx_pool);
    cudaFree(d_cy_pool);
    cudaFree(d_rho);
    cudaFree(d_u);
    cudaFree(d_v);
    cudaFree(d_pres);
    cudaFree(d_temp);
    cudaFree(d_rhou);
    cudaFree(d_rhov);
    cudaFree(d_E);
    cudaFree(d_rho_new);
    cudaFree(d_rhou_new);
    cudaFree(d_rhov_new);
    cudaFree(d_E_new);
    cudaFree(d_solid);
}

__global__ void Initialization(int NX, int NY, float DX, float DY, float rho_in, float u_in, float v_in,
                                float p_in, float E_in, int *solid, float *rho, float *rhou, float *rhov, 
                                float *E, float *pres, float *u, float *v, float *temp, float *rho_new, 
                                float *rhou_new, float *rhov_new, float *E_new){
    int size_x = NX + 2;
    int size_y = NY + 2;
    int total_size = size_x * size_y;
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= total_size) return;
    int i = idx / size_y;
    int j = idx - i * size_y;

    solid[idx] = FLUID;
    rho[idx]   = rho_in;
    rhou[idx]  = rho_in * u_in;
    rhov[idx]  = rho_in * v_in;
    E[idx]     = E_in;
    pres[idx]  = p_in;
    u[idx]     = u_in;
    v[idx]     = v_in;
    temp[idx]  = p_in / (rho_in * R_GAS);
    rho_new[idx]  = 0.0;
    rhou_new[idx] = 0.0;
    rhov_new[idx] = 0.0;
    E_new[idx]    = 0.0;

    // solid
    if (i >= 1 && i <= NX && j >= 1 && j <= NY) {
        float x = (i-0.5)*DX;
        float y = (j-0.5)*DY;

        if (x >= SBL && y <= SBH) {
            solid[idx] = SOLID;
            rho[idx]   = 0.0;
            rhou[idx]  = 0.0;
            rhov[idx]  = 0.0;
            E[idx]     = 0.0;
            pres[idx]  = 0.0;
            u[idx]     = 0.0;
            v[idx]     = 0.0;
            temp[idx]  = 0.0;
        }
    }
}

__global__ void apply_boundary( int NX, int NY, int size_y, int step_i, int step_j, 
                                float rho_in, float u_in, float v_in, float p_in, 
                                float E_in, float *rho, float *rhou, float *rhov, 
                                float *E, float *pres, float *u, float *v, float *temp){

    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int max_n = (NX > NY) ? NX : NY;
    if (index < max_n){

        /* left Mach 3 inflow */
        if (index < NY){
            int j = index + 1;
            int idx = 0 * size_y + j;
            rho[idx]  = rho_in;
            rhou[idx] = rho_in * u_in;
            rhov[idx] = rho_in * v_in;
            E[idx]    = E_in;
            pres[idx] = p_in;
            u[idx]    = u_in;
            v[idx]    = v_in;
            temp[idx] = p_in / (rho_in * R_GAS);

            /* right outflow */
            int idx_g = (NX + 1) * size_y + j;
            int idx_i = NX * size_y + j;
            rho[idx_g]  = rho[idx_i];
            rhou[idx_g] = rhou[idx_i];
            rhov[idx_g] = rhov[idx_i];
            E[idx_g]    = E[idx_i];
            pres[idx_g] = pres[idx_i];
            u[idx_g]    = u[idx_i];
            v[idx_g]    = v[idx_i];
            temp[idx_g] = temp[idx_i];
        }

        if (index < NX) {
            int i = index + 1;

            /* upper reflective wall */
            int idx_g = i * size_y + (NY + 1);
            int idx_i = i * size_y + NY;
            rho[idx_g]  = rho[idx_i];
            rhou[idx_g] = rhou[idx_i];
            rhov[idx_g] = -rhov[idx_i];
            E[idx_g]    = E[idx_i];
            pres[idx_g] = pres[idx_i];
            u[idx_g]    = u[idx_i];
            v[idx_g]    = -v[idx_i];
            temp[idx_g] = temp[idx_i];

            /* lower reflective wall before step, step-top reflective wall after step */
            if (i <= step_i) {
                idx_g = i * size_y;
                idx_i = i * size_y + 1;
            } else {
                idx_g = i * size_y + step_j;
                idx_i = i * size_y + (step_j + 1);
            }

            rho[idx_g]  = rho[idx_i];
            rhou[idx_g] = rhou[idx_i];
            rhov[idx_g] = -rhov[idx_i];
            E[idx_g]    = E[idx_i];
            pres[idx_g] = pres[idx_i];
            u[idx_g]    = u[idx_i];
            v[idx_g]    = -v[idx_i];
            temp[idx_g] = temp[idx_i];
        }

        /* vertical wall at the step front */
        if (index < step_j) {
            int j = index + 1;
            int idx_g = (step_i + 1) * size_y + j;
            int idx_i = step_i * size_y + j;
            rho[idx_g]  = rho[idx_i];
            rhou[idx_g] = -rhou[idx_i];
            rhov[idx_g] = rhov[idx_i];
            E[idx_g]    = E[idx_i];
            pres[idx_g] = pres[idx_i];
            u[idx_g]    = -u[idx_i];
            v[idx_g]    = v[idx_i];
            temp[idx_g] = temp[idx_i];
        }
    }
}

__global__ void find_block_max( int NX, int NY, int size_y, int *solid, float *rho, float *pres,
                            float *u, float *v, float *temp, float *block_max ){
    
    // 每個 cell 先估計自己的 x 方向最大粒子速度、y 方向最大粒子速度， 取比較大的那個當作這個 cell 的 local_max
    int tid = threadIdx.x;
    int N = NX * NY;
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    float local_max = 0.0;
    __shared__ float sdata[threads];

    if(index < N){
        int i = index / NY + 1;
        int j = index % NY + 1;
        int idx = i * size_y + j;

        if(solid[idx] != SOLID && rho[idx] > 1e-12 && pres[idx] > 1e-12 && temp[idx] > 0.0){
            float thermal_c = 3 * sqrt(R_GAS * temp[idx]);
            float vx = fabs(u[idx]) + thermal_c;
            float vy = fabs(v[idx]) + thermal_c;
            local_max = (vx > vy) ? vx : vy;
        }
    }

    sdata[tid] = local_max; // 每個thread 把 local_max 放到shared memory
    __syncthreads();

    for (int stride = blockDim.x / 2; stride > 0; stride= stride/2){
        if (tid < stride && sdata[tid + stride] > sdata[tid]) sdata[tid] = sdata[tid + stride];
        __syncthreads();
    }

    // 每個 block 只讓第 0 個 thread，把這個 block 算出來的最大值存到 global memory
    if (tid == 0) block_max[blockIdx.x] = sdata[0];
}

float rand_normal(){
    float u1 = (float)rand()/RAND_MAX;
    float u2 = (float)rand()/RAND_MAX;
    if (u1 < 1e-10) u1 = 1e-10;
    return sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);
}

void normalize_velocity_pool(){
    float mean_x = 0.0;
    float mean_y = 0.0;

    for (int p = 0; p < Nf; p++) {
        h_cx_pool[p] = rand_normal();
        h_cy_pool[p] = rand_normal();
        mean_x += h_cx_pool[p];
        mean_y += h_cy_pool[p];
    }

    mean_x /= (float)Nf;
    mean_y /= (float)Nf;
    float var_x = 0.0;
    float var_y = 0.0;

    for (int p = 0; p < Nf; p++) {
        h_cx_pool[p] -= mean_x;
        h_cy_pool[p] -= mean_y;
        var_x += h_cx_pool[p] * h_cx_pool[p];
        var_y += h_cy_pool[p] * h_cy_pool[p];
    }

    var_x /= (float)Nf;
    var_y /= (float)Nf;
    float std_x = sqrt(var_x);
    float std_y = sqrt(var_y);

    if (std_x < 1e-6) std_x = 1e-6;
    if (std_y < 1e-6) std_y = 1e-6;
    for (int p = 0; p < Nf; p++){
        h_cx_pool[p] /= std_x;
        h_cy_pool[p] /= std_y;
    }
}

__device__ unsigned int hash_u32(unsigned int x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

__device__ float d_rand(unsigned int seed) {
    unsigned int h = hash_u32(seed);
    return (float)(h & 0x00FFFFFFU) / 16777216.0;
}

__global__ void clear_new( int total_size, float *rho_new, float *rhou_new, float *rhov_new, float *E_new){
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= total_size) return;

    rho_new[idx]  = 0.0;
    rhou_new[idx] = 0.0;
    rhov_new[idx] = 0.0;
    E_new[idx]    = 0.0;
}

__global__ void Pfm_particle(int NX, int NY, int size_y, float DX, float DY, float dt, int step, float rho_in, float u_in, float v_in, 
                            float p_in, int *solid, float *rho, float *pres, float *u, float *v, float *temp, float *cx_pool,  
                            float *cy_pool, float *rho_new,float *rhou_new,float *rhov_new,float *E_new,int total_particles){

    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < total_particles){

        // cell裡第幾顆粒子
        int p_idx = index % Nf;     /* index = 0~99    -> pp = 0~99
                                       index = 100~199 -> pp = 0~99  */
        // 這顆粒子屬於第幾個cell                            
        int cell_idx = index / Nf;  

        // 把 cell_idx 轉成2D座標
        int i = cell_idx / NY;          
        int j = (cell_idx - i * NY) + 1;
        int src_idx = i * size_y + j;  // 2D座標轉成陣列 index。

        int is_inflow   = (i == 0);
        int is_physical = (i >= 1 && i <= NX);
        float rho_s, u_s, v_s, p_s, T_s;

        if (is_physical) {
            if (solid[src_idx] == SOLID) return;
            if ( rho[src_idx] <= 1e-12) return;
            if (pres[src_idx] <= 1e-12) return;
        }
        if (is_inflow) {
            rho_s = rho_in;
            u_s   = u_in;
            v_s   = v_in;
            p_s   = p_in;
            T_s   = p_s / (rho_s * R_GAS);
        } else {
            rho_s = rho[src_idx];
            u_s   = u[src_idx];
            v_s   = v[src_idx];
            p_s   = pres[src_idx];
            T_s   = temp[src_idx];
        }

        float m_p = rho_s / (float)Nf;
        float sqrt_RT = sqrt(R_GAS * T_s);

        float full_internal_e  = p_s / ((GAMMA - 1.0) * rho_s);
        float extra_internal_e = full_internal_e - R_GAS * T_s;
        if (extra_internal_e < 0.0) extra_internal_e = 0.0;

        float p_vx = u_s + sqrt_RT * cx_pool[p_idx];
        float p_vy = v_s + sqrt_RT * cy_pool[p_idx];

        unsigned int seed = (unsigned int)(index + step * total_particles);
        float rx = d_rand(seed + 20 ) * DX;
        float ry = d_rand(seed + 10) * DY;

        /* This formula also gives x0 = -DX + rx for the inflow source i = 0. */
        float x0 = (i - 1) * DX + rx;
        float y0 = (j - 1) * DY + ry;
        float x1 = x0 + p_vx * dt;
        float y1 = y0 + p_vy * dt;

        /*
        int target_i = (int)floor(x1 / DX) + 1;
        int target_j = (int)floor(y1 / DY) + 1;

        if (target_i < 1) return;
        if (target_i > NX) return;

        if (target_j < 1 || target_j > NY) {
            target_i = i;
            target_j = j;
            p_vy = -p_vy;
        }

        int tgt_idx = target_i * size_y + target_j;
        if (solid[tgt_idx] == SOLID) {
            if (is_inflow) return;

            int old_target_i = target_i;
            int old_target_j = target_j;

            target_i = i;
            target_j = j;
            tgt_idx = src_idx;

            if (old_target_i != i) p_vx = -p_vx;
            if (old_target_j != j) p_vy = -p_vy;
        }*/

        if (y1 < 0.0) {
            y1 = -y1;
            p_vy = -p_vy;
        }

        if (y1 > 1.0) {
            y1 = 2.0 * 1.0 - y1;
            p_vy = -p_vy;
        }

        // 撞到 step 前方垂直牆 x = SBL
        // 粒子從左邊流體區進入 solid 區
        if (x0 < SBL && x1 >= SBL && y1 <= SBH) {
            x1 = 2.0 * SBL - x1;
            p_vx = -p_vx;
        }

        // 撞到step上方水平牆 y=SBH
        if (y0 > SBH && y1 <= SBH && x1 >= SBL) {
            y1 = 2.0 * SBH - y1;
            p_vy = -p_vy;
        }

        // 用反射後的位置重新計算 target cell
        int target_i = (int)floorf(x1 / DX) + 1;
        int target_j = (int)floorf(y1 / DY) + 1;

        // 檢查是否離開計算域
        if (target_i < 1) return;
        if (target_i > NX) return;
        if (target_j < 1) return;
        if (target_j > NY) return;

        int tgt_idx = target_i * size_y + target_j;
        float particle_E = m_p * (0.5 * (p_vx * p_vx + p_vy * p_vy) + extra_internal_e);

        atomicAdd(&rho_new[tgt_idx],  m_p);
        atomicAdd(&rhou_new[tgt_idx], m_p * p_vx);
        atomicAdd(&rhov_new[tgt_idx], m_p * p_vy);
        atomicAdd(&E_new[tgt_idx], particle_E);
    }
}

__global__ void update_primitives(int NX, int NY, int size_y, int *solid, float *rho_new, float *rhou_new, float *rhov_new, float *E_new, 
                                float *rho, float *rhou, float *rhov, float *E, float *pres, float *u, float *v, float *temp){
                                    
    int linear = blockIdx.x * blockDim.x + threadIdx.x;
    int ncell = NX * NY;
    if (linear >= ncell) return;

    int ii = linear / NY;
    int jj = linear - ii * NY;
    int i = ii + 1;
    int j = jj + 1;
    int idx = i * size_y + j;

    if (solid[idx] == SOLID) {
        rho[idx]  = 0.0;
        rhou[idx] = 0.0;
        rhov[idx] = 0.0;
        E[idx]    = 0.0;
        pres[idx] = 0.0;
        u[idx]    = 0.0;
        v[idx]    = 0.0;
        temp[idx] = 0.0;
        return;
    }

    float r = rho_new[idx];
    float ru = rhou_new[idx];
    float rv = rhov_new[idx];
    float e_total = E_new[idx];

    if (r < 1e-8) r = 1e-8;

    float ux = ru / r;
    float vy = rv / r;

    float ke_density = 0.5 * r * (ux * ux + vy * vy);
    float p = (GAMMA - 1.0) * (e_total - ke_density);

    if (p < 1e-8) {
        p = 1e-8;
        e_total = p / (GAMMA - 1.0) + ke_density;
    }

    rho[idx]  = r;
    rhou[idx] = ru;
    rhov[idx] = rv;
    E[idx]    = e_total;
    pres[idx] = p;
    u[idx]    = ux;
    v[idx]    = vy;
    temp[idx] = p / (r * R_GAS);
}

int main(int argc, char *argv[]){
    if (argc != 4){
        fprintf(stderr, "Usage: %s NX NY T_END\n", argv[0]);
        return 1;
    }
    int NX = atoi(argv[1]);
    int NY = atoi(argv[2]);
    float t_max = atof(argv[3]);
    srand(2026);
    int size_x = NX + 2;
    int size_y = NY + 2;
    int total_size = size_x * size_y;
    int N = NX * NY;
    float DX = 3.0 / (float)NX;
    float DY = 1.0 / (float)NY;
    int step_i = (int)(SBL / DX);
    int step_j = (int)(SBH / DY);
    float rho_in = 1.4;
    float p_in   = 1.0;
    float u_in   = 3.0;
    float v_in   = 0.0;
    float E_in   = p_in / (GAMMA - 1.0) + 0.5 * rho_in * (u_in * u_in + v_in * v_in);

    int blocks  = (total_size + threads - 1) / threads;
    int blocks_ncell = (N + threads - 1) / threads;
    int boundary= (((NX > NY) ? NX : NY) + threads - 1) / threads; 

    // Initialization
    Allocate_Memory(total_size, blocks_ncell);
    Initialization<<<blocks, threads>>>(NX, NY, DX, DY, rho_in, u_in, v_in, p_in, E_in, 
                                        d_solid, d_rho, d_rhou, d_rhov,  d_E, d_pres, d_u, d_v, 
                                        d_temp, d_rho_new, d_rhou_new, d_rhov_new, d_E_new );
    cudaError_t err = cudaDeviceSynchronize();
    if (err != cudaSuccess) printf("Kernel launch error at Initialization: %s\n", cudaGetErrorString(err));
    
    // main
    float t = 0.0;
    int step = 0;
    while (t < t_max){

        apply_boundary <<<boundary,threads>>>(NX, NY, size_y, step_i, step_j, rho_in, u_in, v_in, p_in, 
                                            E_in, d_rho, d_rhou, d_rhov, d_E, d_pres, d_u, d_v, d_temp);
        err = cudaDeviceSynchronize();
        if (err != cudaSuccess) {
            printf("Kernel launch error at Apply_Boundary: %s\n", cudaGetErrorString(err));
            break;
        }

        find_block_max <<<blocks_ncell,threads>>>(NX, NY, size_y, d_solid, d_rho, d_pres, d_u, d_v, 
                                              d_temp, d_block_max); // 找出這個 block 裡最大的 local_max
        err = cudaDeviceSynchronize();
        if (err != cudaSuccess) {
            printf("Kernel execution error at find_block_max: %s\n", cudaGetErrorString(err));
            break;
        }

        err =cudaMemcpy(h_block_max, d_block_max, blocks_ncell*sizeof(float), cudaMemcpyDeviceToHost);
        if (err != cudaSuccess) {
            printf("Kernel execution error at cudaMemcpy- h_block_max, d_block_max: %s\n", cudaGetErrorString(err));
            break;
        }

        float max_v = 0.0;
        for (int b = 0; b < blocks_ncell; b++) if (h_block_max[b] > max_v) max_v = h_block_max[b];
        if (max_v < 1e-12) max_v = 1e-12;

        float dt = CFL * fmin(DX, DY) / max_v;
        if (t + dt > t_max) dt = t_max - t;

        normalize_velocity_pool();
        err = cudaMemcpy(d_cx_pool, h_cx_pool, Nf * sizeof(float), cudaMemcpyHostToDevice);
        if (err != cudaSuccess){
            printf("Memcpy- h_cx_pool to d_cx_pool: %s\n", cudaGetErrorString(err));
            break;
        }
        err = cudaMemcpy(d_cy_pool, h_cy_pool, Nf * sizeof(float), cudaMemcpyHostToDevice);
        if (err != cudaSuccess){
            printf("Memcpy- h_cy_pool to d_cy_pool: %s\n", cudaGetErrorString(err));
            break;
        }

        int cell_count = (NX + 1) * NY; // 有粒子的cell數量
        int total_particles  = cell_count * Nf; // 有粒子的cell數量 * Nf
        int blocks_particles = (total_particles + threads - 1) / threads;
        clear_new <<<blocks, threads>>>(total_size,d_rho_new, d_rhou_new, d_rhov_new, d_E_new);
        Pfm_particle <<<blocks_particles, threads>>>(NX, NY, size_y, DX, DY, dt, step, rho_in, u_in, v_in, p_in, 
                                                    d_solid, d_rho, d_pres, d_u, d_v, d_temp, d_cx_pool, d_cy_pool, 
                                                    d_rho_new, d_rhou_new, d_rhov_new, d_E_new, total_particles);    
        err = cudaDeviceSynchronize();
        if (err != cudaSuccess){
            printf("Kernel launch error at Initialization: %s\n", cudaGetErrorString(err));
            break;
        }

        update_primitives <<<blocks_ncell, threads>>>(NX, NY, size_y, d_solid, d_rho_new, d_rhou_new, d_rhov_new, 
                                                    d_E_new, d_rho, d_rhou, d_rhov, d_E, d_pres, d_u, d_v, d_temp);
        err = cudaDeviceSynchronize();
        if (err != cudaSuccess){
            printf("Kernel launch error at Initialization: %s\n", cudaGetErrorString(err));
            break;
        }

        t += dt;
        step++;

        if (step % 200 == 0) {
            printf("Step: %d, Time: %.6f / %.6f, dt = %.6e, max_v = %.6e\n", step, t, t_max, dt, max_v);
        }
    }

    cudaMemcpy(h_rho, d_rho, total_size * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_u, d_u, total_size * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_v, d_v, total_size * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_pres, d_pres, total_size * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_solid, d_solid, total_size * sizeof(int), cudaMemcpyDeviceToHost);

    FILE *fp = fopen("results.txt", "w");
    if (!fp) {
        fprintf(stderr, "Could not open results.txt\n");
        return 1;
    }

    for (int j = 1; j <= NY; j++) {
        for (int i = 1; i <= NX; i++) {
            int id = i * size_y + j;
            float x = (i - 0.5) * DX;
            float y = (j - 0.5) * DY;
            fprintf(fp, "%f %f %f %f %f %f %d\n", x, y, h_rho[id], h_u[id], h_v[id], h_pres[id], h_solid[id]);
        }
    }
    fclose(fp);
    printf("results.txt done\n");

    Free_Memory();

    return 0;
}
